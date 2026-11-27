# Red base: VPC con subnets públicas, un Internet Gateway y los tres grupos de
# seguridad del sistema.
#
# Se usan subnets públicas porque las tareas de Fargate necesitan salida a
# internet para descargar las imágenes de GHCR. Evitar el NAT Gateway ahorra
# aproximadamente USD 32 por mes, que sobre el presupuesto de AWS Academy es
# significativo. Los grupos de seguridad mantienen el tráfico de entrada
# restringido al ALB.

locals {
  name_prefix = "${var.project}-${var.environment}"
  subnet_map  = { for index, az in var.availability_zones : az => index }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.subnet_map

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value + 1)
  # Las tareas piden IP pública explícitamente en su network_configuration
  # (assign_public_ip = true). La subnet no necesita asignarla por defecto.
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Recibe el tráfico de internet y lo reparte a los servicios.
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "Entrada HTTP publica hacia el ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP desde internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Puerto del panel de administracion"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida hacia las tareas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Recibe el trafico de las tareas hacia los servicios internos. No se expone a
# internet: solo acepta conexiones del grupo de seguridad de las tareas.
resource "aws_security_group" "internal_alb" {
  name_prefix = "${local.name_prefix}-internal-"
  description = "Entrada desde las tareas hacia el ALB interno"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Servicios internos dentro de la VPC"
    from_port   = 8082
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Salida hacia las tareas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-internal-alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Las tareas se hablan entre si y aceptan trafico del ALB.
resource "aws_security_group" "services" {
  name_prefix = "${local.name_prefix}-services-"
  description = "Trafico entre microservicios y desde el ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Trafico entre las propias tareas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Trafico proveniente del ALB publico"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Trafico proveniente del ALB interno"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  egress {
    description = "Salida a internet y a la base"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-services"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Solo acepta conexiones desde las tareas.
resource "aws_security_group" "database" {
  name_prefix = "${local.name_prefix}-database-"
  description = "Acceso a PostgreSQL y Redis desde las tareas"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.services.id]
  }

  egress {
    description = "Respuestas hacia las tareas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Solo acepta conexiones de las tareas hacia el Redis gestionado.
resource "aws_security_group" "cache" {
  name_prefix = "${local.name_prefix}-cache-"
  description = "Acceso a Redis desde las tareas"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.services.id]
  }

  egress {
    description = "Respuestas hacia las tareas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cache"
  })

  lifecycle {
    create_before_destroy = true
  }
}
