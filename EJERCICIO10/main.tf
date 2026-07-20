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

  endpoints {
    sts = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "flocorp_eventos" {
  bucket = "flocorp_eventos_raw"
  tags = {
    Environment = "dev"
    Project     = "flocorp_eventos"
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
  tags = {
    Environment = "dev"
    project     = "flocorp_lambda"
  }
}

resource "aws_iam_policy" "flocorp_s3_write" {
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

        Resources = [
          "${aws_s3_bucket.flocorp_eventos.arn}",
          "${aws_s3_bucket.flocorp_eventos.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "adjuntar_politica" {
  role       = aws_iam_role.flocorp_lambda_role.name
  policy_arn = aws_iam_policy.flocorp_s3_write.arn
}