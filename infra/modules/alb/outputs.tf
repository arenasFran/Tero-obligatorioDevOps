output "alb_arn" {
  description = "ARN del Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Nombre DNS del ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Zona alojada del ALB, para crear un alias de Route 53."
  value       = aws_lb.this.zone_id
}

output "target_group_arns" {
  description = "ARN de cada target group, indexado por el nombre del listener."
  value       = { for name, target_group in aws_lb_target_group.this : name => target_group.arn }
}
