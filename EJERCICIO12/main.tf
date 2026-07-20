terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
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

resource "aws_s3_bucket" "flocorp_eventos" {
  bucket = "flocorp_eventos_raw"

  tags = {
    Environment = "dev"
    Project     = "flocorp"
  }
}

resource "aws_dynamodb_table" "flocorp_sessions" {
  name         = "flocorp_sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  tags = {
    Environment = "dev"
    Project     = "flocorp"
  }
}

resource "aws_iam_role" "flocorp_lambda_role" {
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
}

resource "aws_iam_policy" "flocorp_s3_write_policy" {
  name = "flocorp_s3_write_policy"
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
          "${aws_s3_bucket.flocorp_eventos.arn}",
          "${aws_s3_bucket.flocorp_eventos.arn}/*"
        ]
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = "${aws_dynamodb_table.flocorp_sessions}"
      }
    ]

  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.flocorp_lambda_role.name
  policy_arn = aws_iam_policy.flocorp_s3_write_policy.arn
}

resource "aws_iam_policy" "lambda_logs_policy"{
    name = "flocorp_lambda_logs_policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
            Effect = "Allow"
            Resource = "*"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "attach_log_policy"{
    role = aws_iam_role.flocorp_lambda_role.name
    policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_logs"{
    name = "/aws/lambda/flocorp_processor"
    retention_in_days = 1
}

resource "aws_lambda_function" "flocorp_processor" {
  function_name = "flocorp_processor"
  filename      = "lambda.zip"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.flocorp_lambda_role.arn

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.flocorp_eventos.arn
      TABLE_NAME  = aws_dynamodb_table.flocorp_sessions.name
    }
  }
}