terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# PostgreSQL gestionado.
#
# La contraseña se genera con random_password y se guarda en Secrets Manager.
# El estado de Terraform contiene el valor cifrado en S3 (SSE-S3), pero ningún
# archivo del repositorio ni ningún .tfvars lo expone. Las tareas de ECS la leen
# del secreto en tiempo de arranque.

locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db"
  })
}

# Las aplicaciones legacy abren la conexión con sslmode=disable, así que RDS
# (que en PostgreSQL 16 exige SSL por defecto) las rechaza con
# "no pg_hba.conf entry ... no encryption".
#
# rds.force_ssl es un parámetro dinámico: se puede desactivar sin reiniciar la
# instancia. La base no es pública y solo acepta el puerto 5432 desde el
# security group de las tareas, dentro de la VPC.
#
# Deuda técnica: habilitar TLS en catalog, orders, carts y admin, y volver a
# force_ssl=1. Requiere recompilar imágenes y pasar por el pipeline de main.
resource "aws_db_parameter_group" "this" {
  name        = "${local.name_prefix}-postgres16"
  family      = "postgres16"
  description = "Parámetros de PostgreSQL del ambiente ${var.environment}"

  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "immediate"
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-postgres16"
  })
}

resource "aws_db_instance" "this" {
  identifier = "${local.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # Entorno de desarrollo: sin snapshots ni protección contra borrado, para que
  # `terraform destroy` libere el presupuesto del laboratorio.
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  apply_immediately       = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-postgres"
  })
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name_prefix}/postgres"
  description             = "Credenciales de PostgreSQL del ambiente ${var.environment}"
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-postgres"
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.username
    password = random_password.db.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}
