# Empaquetado del código
data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/upload-lambda"
  output_path = "${path.module}/upload.zip"
}

data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/crop-lambda"
  output_path = "${path.module}/crop.zip"
}

# UPLOAD
resource "aws_lambda_function" "upload_lambda" {
  filename         = data.archive_file.upload_zip.output_path
  function_name    = "proyectoaws-upload-${terraform.workspace}"
  role             = aws_iam_role.upload_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.upload_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.image_bucket.id
      QUEUE_URL   = aws_sqs_queue.image_queue.url
    }
  }

  # Configuración de red 
  vpc_config {
    subnet_ids         = [aws_subnet.priv_a.id, aws_subnet.priv_b.id]
    security_group_ids = [aws_security_group.vpce_sqs_sg.id]
  }
}

#  CROP 
resource "aws_lambda_function" "crop_lambda" {
  filename         = data.archive_file.crop_zip.output_path
  function_name    = "proyectoaws-crop-${terraform.workspace}"
  role             = aws_iam_role.crop_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  timeout          = 30 # Más tiempo para procesar imágenes
  source_code_hash = data.archive_file.crop_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.image_bucket.id
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.priv_a.id, aws_subnet.priv_b.id]
    security_group_ids = [aws_security_group.vpce_sqs_sg.id]
  }
}

# Triggers
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.image_queue.arn
  function_name    = aws_lambda_function.crop_lambda.arn
  enabled          = true
  batch_size       = 1
}