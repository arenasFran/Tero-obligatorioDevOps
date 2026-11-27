terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "project" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente al que pertenece el clúster."
  type        = string
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_ecs_cluster" "this" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = local.name_prefix
  })
}

# Cloud Map está bloqueado por la política de AWS Academy
# (servicediscovery:CreatePrivateDnsNamespace y CreateHttpNamespace), así que el
# descubrimiento se resuelve con un ALB interno. Ver docs/adr/0004-sin-cloud-map.md.

output "cluster_arn" {
  description = "ARN del clúster de ECS."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Nombre del clúster de ECS."
  value       = aws_ecs_cluster.this.name
}


