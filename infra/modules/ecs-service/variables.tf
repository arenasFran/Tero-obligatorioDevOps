variable "project" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente al que pertenece el servicio."
  type        = string
}

variable "cluster_arn" {
  description = "ARN del clúster de ECS donde corre el servicio."
  type        = string
}

variable "service_name" {
  description = "Nombre del servicio y del contenedor. También es el nombre DNS."
  type        = string
}

variable "image" {
  description = "Imagen completa, con tag inmutable (SHA del commit)."
  type        = string
}

variable "container_port" {
  description = "Puerto que escucha el contenedor."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Unidades de CPU de la tarea (256 = 0.25 vCPU)."
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memoria de la tarea en MB."
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Cantidad de tareas que mantiene el servicio."
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Subnets donde se lanzan las tareas."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Grupos de seguridad de las tareas."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Asigna IP pública a la tarea para descargar imágenes."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "Rol que usa ECS para descargar la imagen, escribir logs y leer secretos."
  type        = string
}

variable "task_role_arn" {
  description = "Rol que usa la aplicación. Si es null, la tarea no tiene rol propio."
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Variables de entorno no sensibles."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Variables de entorno leídas de Secrets Manager (nombre => valueFrom)."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Días que CloudWatch conserva los logs del servicio."
  type        = number
  default     = 7
}

variable "target_group_arn" {
  description = "Target group del ALB. Si es null, el servicio no se publica."
  type        = string
  default     = null
}

variable "health_check_grace_period" {
  description = "Segundos que el ALB espera antes de exigir salud, solo con target group."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
