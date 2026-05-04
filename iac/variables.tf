variable "nombre_proyecto" {
  description = "Nombre base para los recursos"
  type        = string
  default     = "aws_proyecto"
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

variable "upload_lambda_name" {
  description = "Nombre base de la funcion lambda de carga"
  type        = string
  default     = "upload-image-func"
}

variable "crop_lambda_name" {
  description = "Nombre base de la funcion lambda de procesamiento"
  type        = string
  default     = "crop-image-func"
}