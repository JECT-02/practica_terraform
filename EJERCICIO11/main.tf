terraform{
    required_providers {
      aws = {
        source = "hashicorp/aws",
        version = "~> 5.0"
      }
    }
}

provider "aws" {
    region = "us-east-1"

    access_key = "test"
    secret_key = "test"

    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_requesting_account_id = true
    s3_use_path_style = true

    endpoints{
        s3 = "http://localhost:4566"
        sts = "http://localhost:4566"
    }
}

resource "aws_s3_bucket" "flocorp_eventos"{
    bucket = "flocorp_eventos_raw"
    tags = {
        Environment = "dev"
        project = "flocorp"
    }
}

resource "aws_iam_role" "flocorp_lambda_role"{
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

resource "aws_iam_policy" "flocorp_politica_s3"{
    name = "flocorp_policy_write_s3"
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
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "adjuntar_politica"{
    role = aws_iam_role.flocorp_lambda_role.name
    policy_arn = aws_iam_policy.flocorp_politica_s3.arn
}

resource "aws_lambda_function" "flocorp_proccesor"{
    function_name = "flocorp_processor"
    filename = "lambda.zip"
    handler = "handler.lambda_handler"
    runtime = "python3.12"
    role = aws_iam_role.flocorp_lambda_role.arn
}