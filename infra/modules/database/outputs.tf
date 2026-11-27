output "endpoint" {
  description = "Host de conexión de PostgreSQL."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Puerto de PostgreSQL."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Base de datos creada por RDS."
  value       = aws_db_instance.this.db_name
}

output "secret_arn" {
  description = "ARN del secreto con usuario y contraseña."
  value       = aws_secretsmanager_secret.db.arn
}

output "instance_identifier" {
  description = "Identificador de la instancia de RDS."
  value       = aws_db_instance.this.identifier
}
