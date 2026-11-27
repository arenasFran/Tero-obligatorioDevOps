output "service_name" {
  description = "Nombre del servicio de ECS."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN de la task definition en uso."
  value       = aws_ecs_task_definition.this.arn
}

output "log_group_name" {
  description = "Grupo de CloudWatch donde escribe el servicio."
  value       = aws_cloudwatch_log_group.this.name
}


