output "vpc_id" {
  description = "ID de la VPC del ambiente dev."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Subnets públicas donde se despliegan el ALB y las tareas."
  value       = module.network.public_subnet_ids
}

output "alb_security_group_id" {
  description = "Grupo de seguridad del ALB."
  value       = module.network.alb_security_group_id
}

output "services_security_group_id" {
  description = "Grupo de seguridad de las tareas."
  value       = module.network.services_security_group_id
}

output "database_security_group_id" {
  description = "Grupo de seguridad de la base y Redis."
  value       = module.network.database_security_group_id
}

output "database_endpoint" {
  description = "Host de PostgreSQL del ambiente dev."
  value       = module.database.endpoint
}

output "database_secret_arn" {
  description = "Secreto de Secrets Manager con las credenciales de la base."
  value       = module.database.secret_arn
}
