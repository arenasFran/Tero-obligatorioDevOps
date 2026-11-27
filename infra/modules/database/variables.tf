variable "project" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente al que pertenece la base."
  type        = string
}

variable "vpc_id" {
  description = "VPC donde se despliega la instancia."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets del grupo de base de datos (al menos dos zonas)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Grupos de seguridad que pueden conectarse a PostgreSQL."
  type        = list(string)
}

variable "instance_class" {
  description = "Clase de instancia de RDS."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Almacenamiento en GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Base de datos inicial. Las demás se crean con init-db.sql."
  type        = string
  default     = "orders"
}

variable "username" {
  description = "Usuario administrador de PostgreSQL."
  type        = string
  default     = "retail_user"
}

variable "backup_retention_days" {
  description = "Días de retención de backups automáticos de RDS."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
