variable "project" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente del despliegue (dev, test, prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC del ambiente."
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidad donde se despliega el ambiente."
  type        = list(string)
}

variable "image_prefix" {
  description = "Prefijo de las imágenes publicadas en GHCR."
  type        = string
  default     = "ghcr.io/arenasfran/tero-obligatoriodevops"
}

variable "image_tag" {
  description = "SHA del commit que se despliega. Tiene que existir en GHCR."
  type        = string
}

variable "desired_count" {
  description = "Cantidad de tareas por servicio."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "Días que CloudWatch conserva los logs."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Etiquetas adicionales para todos los recursos."
  type        = map(string)
  default     = {}
}
