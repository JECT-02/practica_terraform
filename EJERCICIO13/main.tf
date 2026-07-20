terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3       = "http://localhost:4566"
    sts      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}

resource "aws_dynamodb_table" "flocorp_sesiones" {
  name         = "flocorp_sesiones"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sesion_id"
  range_key    = "event_timestamp"

  attribute {
    name = "sesion_id"
    type = "S"
  }
  attribute {
    name = "event_timestamp"
    type = "S"
  }

  ttl {
    enabled        = true
    attribute_name = "event_timestamp"
  }

  tags = {
    Environment = "dev"
    Project     = "flocorp"
  }
}

resource "aws_s3_bucket" "flocorp_eventos_raw" {
  bucket = "flocorp_eventos_raw"
  tags = {
    Environment = "dev"
    Project     = "flocorp"
  }
}

resource "aws_iam_role" "flocorp_lambda_exec_role" {
  name = "flocorp_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "dev"
    Project     = "flocorp"
  }
}

resource "aws_iam_policy" "flocorp_lambda_policy" {
  name = "flocorp_lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]

        Effect = "Allow"

        Resource = [
          "${aws_s3_bucket.flocorp_eventos_raw.arn}",
          "${aws_s3_bucket.flocorp_eventos_raw.arn}/*"
        ]
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]

        Effect = "Allow"

        Resource = "${aws_dynamodb_table.flocorp_sesiones}"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "dev"
    Project     = "flocorp"
  }
} #aqui quiza sea mejor separar en pequeñas politicas separadas

resource "aws_iam_role_policy_attachment" "adjuntar_politica_lambda" {
  role       = aws_iam_role.flocorp_lambda_exec_role.name
  policy_arn = aws_iam_policy.flocorp_lambda_policy.arn
}

resource "aws_lambda_function" "flocorp_lambda_processor" {
  function_name = "flocorp_processor"
  filename      = "lambda.zip"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.flocorp_lambda_exec_role.arn
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      BUCKET_ARN = aws_s3_bucket.flocorp_eventos_raw.arn
      TABLE_NAME = aws_dynamodb_table.flocorp_sesiones.name
    }
  }
}