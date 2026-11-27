output "vpc_id" {
  description = "ID de la VPC del ambiente."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Subnets públicas donde se despliegan los balanceadores y las tareas."
  value       = module.network.public_subnet_ids
}

output "alb_security_group_id" {
  description = "Grupo de seguridad del ALB público."
  value       = module.network.alb_security_group_id
}

output "internal_alb_security_group_id" {
  description = "Grupo de seguridad del ALB interno."
  value       = module.network.internal_alb_security_group_id
}

output "services_security_group_id" {
  description = "Grupo de seguridad de las tareas de ECS."
  value       = module.network.services_security_group_id
}

output "database_security_group_id" {
  description = "Grupo de seguridad de PostgreSQL."
  value       = module.network.database_security_group_id
}

output "cache_security_group_id" {
  description = "Grupo de seguridad de Redis."
  value       = module.network.cache_security_group_id
}

output "database_endpoint" {
  description = "Host de PostgreSQL del ambiente."
  value       = module.database.endpoint
}

output "database_port" {
  description = "Puerto de PostgreSQL del ambiente."
  value       = module.database.port
}

output "database_name" {
  description = "Base de datos creada por RDS."
  value       = module.database.database_name
}

output "database_secret_arn" {
  description = "Secreto de Secrets Manager con las credenciales de la base."
  value       = module.database.secret_arn
}

output "alb_dns_name" {
  description = "Nombre DNS público del ALB."
  value       = module.alb.alb_dns_name
}

output "internal_alb_dns_name" {
  description = "Nombre DNS interno del ALB que usan los microservicios."
  value       = module.internal_alb.alb_dns_name
}

output "ui_target_group_arn" {
  description = "Target group de la tienda."
  value       = module.alb.target_group_arns["ui"]
}

output "admin_target_group_arn" {
  description = "Target group del panel de administración."
  value       = module.alb.target_group_arns["admin"]
}

output "redis_endpoint" {
  description = "Host de Redis."
  value       = module.redis.endpoint
}

output "redis_port" {
  description = "Puerto de Redis."
  value       = module.redis.port
}

output "cluster_arn" {
  description = "ARN del clúster de ECS."
  value       = module.ecs_cluster.cluster_arn
}

output "cluster_name" {
  description = "Nombre del clúster de ECS."
  value       = module.ecs_cluster.cluster_name
}
