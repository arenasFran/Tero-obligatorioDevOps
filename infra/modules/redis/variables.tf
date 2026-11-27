variable "project" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente al que pertenece la caché."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets donde se despliega la caché."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Grupos de seguridad que pueden conectarse a Redis."
  type        = list(string)
}

variable "node_type" {
  description = "Tipo de nodo de ElastiCache."
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Versión de Redis."
  type        = string
  default     = "7.1"
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
