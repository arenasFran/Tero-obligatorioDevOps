# Redis gestionado con ElastiCache.
#
# Reemplaza al contenedor de Redis del docker-compose. Se eligió ElastiCache en
# lugar de un servicio de ECS porque Cloud Map está bloqueado en AWS Academy y
# un ALB no puede balancear TCP. ElastiCache entrega un endpoint estable sin
# necesidad de descubrimiento.
#
# Es una caché: no guarda datos críticos y no tiene backups.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_prefix}-redis"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis"
  })
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = var.security_group_ids

  apply_immediately        = true
  snapshot_retention_limit = 0
  maintenance_window       = "sun:05:00-sun:06:00"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis"
  })
}
