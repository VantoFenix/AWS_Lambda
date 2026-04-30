
#  S3 


# Bucket principal para imágenes
resource "aws_s3_bucket" "image_bucket" {
  bucket        = "proyectoaws-storage-${terraform.workspace}"
  force_destroy = true 

  tags = { 
    Name        = "proyectoaws-bucket-${terraform.workspace}"
    Environment = terraform.workspace
  }
}


# configuracon para borrar automáticamente cualquier archivo después de 1 dia
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
  name = "proyectoaws-dlq-${terraform.workspace}"
  tags = { 
    Name        = "proyectoaws-dlq-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

# 2 Cola Principal
resource "aws_sqs_queue" "image_queue" {
  name                      = "proyectoaws-queue-${terraform.workspace}"
  delay_seconds             = 0
  message_retention_seconds = 86400 
  receive_wait_time_seconds = 10    

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.image_dlq.arn
    maxReceiveCount     = 3 
  })

  tags = { 
    Name        = "proyectoaws-queue-${terraform.workspace}"
    Environment = terraform.workspace
  }
}