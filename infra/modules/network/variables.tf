variable "project" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente al que pertenece la red (dev, test, prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad donde se crean las subnets públicas."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  description = "Etiquetas adicionales para los recursos de red."
  type        = map(string)
  default     = {}
}
