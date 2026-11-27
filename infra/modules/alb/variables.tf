variable "project" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente al que pertenece el ALB."
  type        = string
}

variable "name_suffix" {
  description = "Sufijo del nombre del ALB (por ejemplo alb o internal)."
  type        = string
}

variable "internal" {
  description = "Si es true, el ALB solo es accesible desde dentro de la VPC."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC donde se despliega el ALB."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets donde se despliega el ALB (al menos dos zonas)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Grupos de seguridad del ALB."
  type        = list(string)
}

variable "listeners" {
  description = "Mapa nombre => listener. Cada entrada crea un listener y su target group."
  type = map(object({
    port                 = number
    target_port          = number
    health_check_path    = string
    health_check_matcher = optional(string, "200")
  }))
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
