#  Política de Confianza 
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ROL PARA LA LAMBDA DE CARGA 
resource "aws_iam_role" "upload_role" {
  name               = "proyectoaws-upload-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Permisos para Upload: Escribir en S3 y Enviar a SQS
resource "aws_iam_role_policy" "upload_policy" {
  name = "proyectoaws-upload-policy-${terraform.workspace}"
  role = aws_iam_role.upload_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {       
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.image_bucket.arn}/*"
      },
      {
        Action   = ["sqs:SendMessage"]
        Effect   = "Allow"
        Resource = aws_sqs_queue.image_queue.arn
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 3  ROL PARA LA LAMBDA DE PROCESAMIENTO 
resource "aws_iam_role" "crop_role" {
  name               = "proyectoaws-crop-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Permisos para Crop: Leer/Escribir en S3 y Leer de SQS
resource "aws_iam_role_policy" "crop_policy" {
  name = "proyectoaws-crop-policy-${terraform.workspace}"
  role = aws_iam_role.crop_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.image_bucket.arn}/*"
      },
      {
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Effect   = "Allow"
        Resource = aws_sqs_queue.image_queue.arn
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}