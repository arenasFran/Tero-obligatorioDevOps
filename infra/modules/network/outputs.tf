output "vpc_id" {
  description = "ID de la VPC del ambiente."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas, en el orden de availability_zones."
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "alb_security_group_id" {
  description = "Grupo de seguridad del Application Load Balancer."
  value       = aws_security_group.alb.id
}

output "services_security_group_id" {
  description = "Grupo de seguridad de las tareas de ECS."
  value       = aws_security_group.services.id
}

output "database_security_group_id" {
  description = "Grupo de seguridad de PostgreSQL y Redis."
  value       = aws_security_group.database.id
}
