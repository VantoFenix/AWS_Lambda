variable "proyectoaws" {
  description = "Nombre base para los recursos"
  type        = string
  default     = "image-processor"
}


variable "config_red" {
  description = "Configuración de red por entorno"
  type = map(object({
    single_nat_gateway = bool
  }))
  default = {
    "dev" = {
      single_nat_gateway = true
    }
    "qa" = {
      single_nat_gateway = true
    }
    "prod" = {
      single_nat_gateway = false
    }
  }
}

