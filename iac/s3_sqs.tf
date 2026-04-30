
#  S3 


# Bucket principal para imágenes
resource "aws_s3_bucket" "image_bucket" {
  bucket        = "proyectoaws-storage-${terraform.workspace}"
  force_destroy = true # Permite borrar todo al final sin errores manuales

  tags = { 
    Name        = "proyectoaws-bucket-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

# REGLA DE CICLO DE VIDA (Protección de costos)
# Borra automáticamente cualquier archivo después de 1 día.
resource "aws_s3_bucket_lifecycle_configuration" "cleanup" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    id     = "delete-after-24h"
    status = "Enabled"
    expiration {
      days = 1
    }
  }
}