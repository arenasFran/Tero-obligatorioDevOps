variable "region" {
  description = "Región de AWS del ambiente."
  type        = string
}

variable "environment" {
  description = "Nombre del ambiente."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidad donde se despliega."
  type        = list(string)
}

variable "image_tag" {
  description = "SHA del commit que se despliega. Tiene que existir en GHCR."
  type        = string
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
