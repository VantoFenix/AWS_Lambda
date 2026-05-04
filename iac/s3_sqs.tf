#  S3 

# Bucket principal para imágenes
resource "aws_s3_bucket" "image_bucket" {
  bucket        = "${var.nombre_proyecto}-storage-${terraform.workspace}"
  force_destroy = true 

  tags = { 
    Name        = "${var.nombre_proyecto}-bucket-${terraform.workspace}"
    Environment = terraform.workspace
  }
}


# configuracion para borrar automáticamente cualquier archivo después de 1 dia
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


#  SQS 

# 1DLQ
resource "aws_sqs_queue" "image_dlq" {
  name = "${var.nombre_proyecto}-dlq-${terraform.workspace}"
  tags = { 
    Name        = "${var.nombre_proyecto}-dlq-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

# 2 Cola Principal
resource "aws_sqs_queue" "image_queue" {
  name                      = "${var.nombre_proyecto}-queue-${terraform.workspace}"
  delay_seconds             = 0
  message_retention_seconds = 86400 
  receive_wait_time_seconds = 10    

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.image_dlq.arn
    maxReceiveCount     = 3 
  })

  tags = { 
    Name        = "${var.nombre_proyecto}-queue-${terraform.workspace}"
    Environment = terraform.workspace
  }
}