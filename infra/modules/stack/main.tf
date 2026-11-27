# Composición de un ambiente completo.
#
# Los ambientes dev, test y prod llaman a este módulo con distinto CIDR y
# distinto archivo de variables. Así la lógica vive una sola vez y los tres
# ambientes son idénticos salvo por los valores de sus .tfvars.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  # AWS Academy no permite crear roles IAM. Todas las tareas usan el rol que el
  # laboratorio ya entrega a la cuenta.
  lab_role_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  db_host   = module.database.endpoint
  db_port   = module.database.port
  db_secret = module.database.secret_arn

  admin_secret = aws_secretsmanager_secret.admin.arn

  # Cloud Map está bloqueado en Academy, así que los servicios internos se
  # alcanzan por el ALB interno. Cada uno tiene su propio puerto.
  internal_url = "http://${module.internal_alb.alb_dns_name}"
  catalog_url  = "${local.internal_url}:8082"
  carts_url    = "${local.internal_url}:8083"
  orders_url   = "${local.internal_url}:8084"
  checkout_url = "${local.internal_url}:8085"

  redis_url = "redis://${module.redis.endpoint}:${module.redis.port}"
}

# ── Red, base, caché y clúster ─────────────────────────────────────────────

module "network" {
  source = "../network"

  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = var.tags
}

module "database" {
  source = "../database"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.database_security_group_id]
  tags               = var.tags
}

module "redis" {
  source = "../redis"

  project            = var.project
  environment        = var.environment
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.cache_security_group_id]
  tags               = var.tags
}

module "ecs_cluster" {
  source = "../ecs-cluster"

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

# ── Balanceadores ──────────────────────────────────────────────────────────

module "alb" {
  source = "../alb"

  project            = var.project
  environment        = var.environment
  name_suffix        = "alb"
  internal           = false
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.alb_security_group_id]
  tags               = var.tags

  listeners = {
    ui = {
      port              = 80
      target_port       = 8080
      health_check_path = "/health"
    }
    admin = {
      port              = 8081
      target_port       = 8080
      health_check_path = "/health"
    }
  }
}

module "internal_alb" {
  source = "../alb"

  project            = var.project
  environment        = var.environment
  name_suffix        = "internal"
  internal           = true
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.internal_alb_security_group_id]
  tags               = var.tags

  listeners = {
    catalog = {
      port              = 8082
      target_port       = 8080
      health_check_path = "/health"
    }
    carts = {
      port              = 8083
      target_port       = 8080
      health_check_path = "/health"
    }
    orders = {
      port              = 8084
      target_port       = 8080
      health_check_path = "/health"
    }
    checkout = {
      port              = 8085
      target_port       = 8080
      health_check_path = "/health"
    }
  }
}

# ── Secretos de la aplicación ──────────────────────────────────────────────
#
# Las credenciales del panel no son de la base: se generan acá y se guardan en
# Secrets Manager. Las tareas las leen al arrancar; no quedan en el compose ni
# en ningún .tfvars.

resource "random_password" "admin_password" {
  length  = 32
  special = false
}

resource "random_password" "admin_jwt_secret" {
  length  = 48
  special = false
}

# Secrets Manager ya cifra en reposo con la clave gestionada aws/secretsmanager.
# Una CMK propia requiere kms:CreateKey, que AWS Academy bloquea.
# nosemgrep: terraform.aws.security.aws-secretsmanager-secret-unencrypted.aws-secretsmanager-secret-unencrypted
resource "aws_secretsmanager_secret" "admin" {
  name                    = "${local.name_prefix}/admin"
  description             = "Credenciales del panel de administración del ambiente ${var.environment}"
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-admin"
  })
}

resource "aws_secretsmanager_secret_version" "admin" {
  secret_id = aws_secretsmanager_secret.admin.id

  secret_string = jsonencode({
    username   = "admin"
    password   = random_password.admin_password.result
    jwt_secret = random_password.admin_jwt_secret.result
  })
}

# ── Inicialización de la base ──────────────────────────────────────────────
#
# RDS solo crea `orders`. Las otras dos bases y la tabla de carritos se crean
# con una tarea one-off que corre dentro de la VPC. El null_resource la lanza
# después de que RDS está disponible y antes de arrancar los servicios.

# CloudWatch cifra los log groups en reposo con claves gestionadas por el
# servicio. Una CMK propia requiere kms:CreateKey, bloqueado en AWS Academy.
# nosemgrep: terraform.aws.security.aws-cloudwatch-log-group-unencrypted.aws-cloudwatch-log-group-unencrypted
resource "aws_cloudwatch_log_group" "db_init" {
  name              = "/ecs/${local.name_prefix}/db-init"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-init"
  })
}

resource "aws_ecs_task_definition" "db_init" {
  family                   = "${local.name_prefix}-db-init"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = local.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "psql"
      image     = "postgres:16-alpine"
      essential = true

      environment = [
        { name = "PGHOST", value = module.database.endpoint },
        { name = "PGPORT", value = tostring(module.database.port) },
        { name = "PGUSER", value = "retail_user" },
        { name = "PGDATABASE", value = "orders" }
      ]

      secrets = [
        { name = "PGPASSWORD", valueFrom = "${module.database.secret_arn}:password::" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.db_init.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "db-init"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-init"
  })
}

resource "null_resource" "db_init" {
  triggers = {
    task_definition = aws_ecs_task_definition.db_init.arn
    sql_hash        = filesha256("${path.module}/../../sql/init-db.sql")
  }

  provisioner "local-exec" {
    command = "${path.module}/../../scripts/run-db-init.sh"

    environment = {
      AWS_REGION      = data.aws_region.current.region
      CLUSTER         = module.ecs_cluster.cluster_name
      TASK_DEFINITION = aws_ecs_task_definition.db_init.arn
      SUBNETS         = join(",", module.network.public_subnet_ids)
      SECURITY_GROUPS = module.network.services_security_group_id
      LOG_GROUP       = aws_cloudwatch_log_group.db_init.name
      SQL_B64         = base64encode(file("${path.module}/../../sql/init-db.sql"))
    }
  }

  depends_on = [module.database, module.ecs_cluster]
}

# ── Servicios ──────────────────────────────────────────────────────────────

module "catalog" {
  source = "../ecs-service"

  project            = var.project
  environment        = var.environment
  cluster_arn        = module.ecs_cluster.cluster_arn
  service_name       = "catalog"
  image              = "${var.image_prefix}-catalog:${var.image_tag}"
  container_port     = 8080
  desired_count      = var.desired_count
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.services_security_group_id]
  execution_role_arn = local.lab_role_arn
  log_retention_days = var.log_retention_days
  target_group_arn   = module.internal_alb.target_group_arns["catalog"]
  tags               = var.tags

  environment_variables = {
    GIN_MODE                            = "release"
    RETAIL_CATALOG_PERSISTENCE_PROVIDER = "postgres"
    RETAIL_CATALOG_PERSISTENCE_ENDPOINT = "${local.db_host}:${local.db_port}"
    RETAIL_CATALOG_PERSISTENCE_DB_NAME  = "catalogdb"
    RETAIL_CATALOG_PERSISTENCE_USER     = "retail_user"
  }

  secrets = {
    RETAIL_CATALOG_PERSISTENCE_PASSWORD = "${local.db_secret}:password::"
  }

  depends_on = [null_resource.db_init]
}

module "carts" {
  source = "../ecs-service"

  project            = var.project
  environment        = var.environment
  cluster_arn        = module.ecs_cluster.cluster_arn
  service_name       = "carts"
  image              = "${var.image_prefix}-carts:${var.image_tag}"
  container_port     = 8080
  desired_count      = var.desired_count
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.services_security_group_id]
  execution_role_arn = local.lab_role_arn
  log_retention_days = var.log_retention_days
  target_group_arn   = module.internal_alb.target_group_arns["carts"]
  tags               = var.tags

  environment_variables = {
    CART_PERSISTENCE_PROVIDER = "postgres"
    CART_POSTGRES_HOST        = local.db_host
    CART_POSTGRES_PORT        = tostring(local.db_port)
    CART_POSTGRES_DB          = "cartdb"
    CART_POSTGRES_USER        = "retail_user"
    PORT                      = "8080"
  }

  secrets = {
    CART_POSTGRES_PASSWORD = "${local.db_secret}:password::"
  }

  depends_on = [null_resource.db_init]
}

module "orders" {
  source = "../ecs-service"

  project            = var.project
  environment        = var.environment
  cluster_arn        = module.ecs_cluster.cluster_arn
  service_name       = "orders"
  image              = "${var.image_prefix}-orders:${var.image_tag}"
  container_port     = 8080
  desired_count      = var.desired_count
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.services_security_group_id]
  execution_role_arn = local.lab_role_arn
  log_retention_days = var.log_retention_days
  target_group_arn   = module.internal_alb.target_group_arns["orders"]
  tags               = var.tags

  environment_variables = {
    GIN_MODE                           = "release"
    RETAIL_ORDERS_PERSISTENCE_ENDPOINT = "${local.db_host}:${local.db_port}"
    RETAIL_ORDERS_PERSISTENCE_NAME     = "orders"
    RETAIL_ORDERS_PERSISTENCE_USERNAME = "retail_user"
  }

  secrets = {
    RETAIL_ORDERS_PERSISTENCE_PASSWORD = "${local.db_secret}:password::"
  }

  depends_on = [null_resource.db_init]
}

module "checkout" {
  source = "../ecs-service"

  project            = var.project
  environment        = var.environment
  cluster_arn        = module.ecs_cluster.cluster_arn
  service_name       = "checkout"
  image              = "${var.image_prefix}-checkout:${var.image_tag}"
  container_port     = 8080
  desired_count      = var.desired_count
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.services_security_group_id]
  execution_role_arn = local.lab_role_arn
  log_retention_days = var.log_retention_days
  target_group_arn   = module.internal_alb.target_group_arns["checkout"]
  tags               = var.tags

  environment_variables = {
    RETAIL_CHECKOUT_PERSISTENCE_PROVIDER  = "redis"
    RETAIL_CHECKOUT_PERSISTENCE_REDIS_URL = local.redis_url
    RETAIL_CHECKOUT_ENDPOINTS_ORDERS      = local.orders_url
  }

  depends_on = [null_resource.db_init, module.redis, module.orders]
}

module "ui" {
  source = "../ecs-service"

  project            = var.project
  environment        = var.environment
  cluster_arn        = module.ecs_cluster.cluster_arn
  service_name       = "ui"
  image              = "${var.image_prefix}-ui:${var.image_tag}"
  container_port     = 8080
  desired_count      = var.desired_count
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.services_security_group_id]
  execution_role_arn = local.lab_role_arn
  log_retention_days = var.log_retention_days
  target_group_arn   = module.alb.target_group_arns["ui"]
  tags               = var.tags

  environment_variables = {
    RETAIL_UI_ENDPOINTS_CATALOG  = local.catalog_url
    RETAIL_UI_ENDPOINTS_CARTS    = local.carts_url
    RETAIL_UI_ENDPOINTS_CHECKOUT = local.checkout_url
    RETAIL_UI_ENDPOINTS_ORDERS   = local.orders_url
  }

  depends_on = [module.catalog, module.carts, module.orders, module.checkout]
}

module "admin" {
  source = "../ecs-service"

  project            = var.project
  environment        = var.environment
  cluster_arn        = module.ecs_cluster.cluster_arn
  service_name       = "admin"
  image              = "${var.image_prefix}-admin:${var.image_tag}"
  container_port     = 8080
  desired_count      = var.desired_count
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.services_security_group_id]
  execution_role_arn = local.lab_role_arn
  log_retention_days = var.log_retention_days
  target_group_arn   = module.alb.target_group_arns["admin"]
  tags               = var.tags

  environment_variables = {
    DB_HOST = local.db_host
    DB_PORT = tostring(local.db_port)
    DB_USER = "retail_user"
  }

  secrets = {
    DB_PASSWORD      = "${local.db_secret}:password::"
    ADMIN_USERNAME   = "${local.admin_secret}:username::"
    ADMIN_PASSWORD   = "${local.admin_secret}:password::"
    ADMIN_JWT_SECRET = "${local.admin_secret}:jwt_secret::"
  }

  depends_on = [null_resource.db_init, aws_secretsmanager_secret_version.admin]
}
