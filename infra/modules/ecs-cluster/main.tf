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

variable "vpc_id" {
  description = "VPC donde se registra el espacio de nombres privado."
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

# Reemplaza los nombres de servicio de Docker Compose. Dentro de la VPC,
# `catalog.tero.local` resuelve a la tarea que esté corriendo.
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "${var.project}.local"
  description = "Descubrimiento de servicios del ambiente ${var.environment}"
  vpc         = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-namespace"
  })
}

output "cluster_arn" {
  description = "ARN del clúster de ECS."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Nombre del clúster de ECS."
  value       = aws_ecs_cluster.this.name
}

output "namespace_id" {
  description = "ID del espacio de nombres de Cloud Map."
  value       = aws_service_discovery_private_dns_namespace.this.id
}

output "namespace_name" {
  description = "Nombre DNS del espacio de nombres."
  value       = aws_service_discovery_private_dns_namespace.this.name
}
