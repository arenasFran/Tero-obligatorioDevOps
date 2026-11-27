output "vpc_id" {
  description = "ID de la VPC del ambiente."
  value       = module.stack.vpc_id
}

output "public_subnet_ids" {
  description = "Subnets públicas donde se despliegan los balanceadores y las tareas."
  value       = module.stack.public_subnet_ids
}

output "alb_security_group_id" {
  description = "Grupo de seguridad del ALB público."
  value       = module.stack.alb_security_group_id
}

output "services_security_group_id" {
  description = "Grupo de seguridad de las tareas de ECS."
  value       = module.stack.services_security_group_id
}

output "database_security_group_id" {
  description = "Grupo de seguridad de PostgreSQL."
  value       = module.stack.database_security_group_id
}

output "database_endpoint" {
  description = "Host de PostgreSQL del ambiente."
  value       = module.stack.database_endpoint
}

output "database_secret_arn" {
  description = "Secreto de Secrets Manager con las credenciales de la base."
  value       = module.stack.database_secret_arn
}

output "ui_url" {
  description = "URL pública de la tienda."
  value       = "http://${module.stack.alb_dns_name}"
}

output "admin_url" {
  description = "URL pública del panel de administración."
  value       = "http://${module.stack.alb_dns_name}:8081"
}

output "internal_alb_dns_name" {
  description = "Nombre DNS interno que usan los microservicios."
  value       = module.stack.internal_alb_dns_name
}

output "redis_endpoint" {
  description = "Host de Redis."
  value       = module.stack.redis_endpoint
}

output "cluster_name" {
  description = "Nombre del clúster de ECS."
  value       = module.stack.cluster_name
}
