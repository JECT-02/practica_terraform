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
    sts      = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}

# rol es una identidad que no pertenece a alguien en especifico, es una identidad que puede ser usada por cualqueir con los permisos
resource "aws_iam_role" "flocorp-lambda-exec-role" {
  name = "flocorp-lambda-exec-role" #Nombre del rol

  assume_role_policy = jsonencode({ # quien puede usar el rol?
    Version = "2012-10-17"          #version de las politicas
    Statement = [
      {
        Action = "sts:AssumeRole" # permite tomar el rol temporalmente con credenciales de sts
        Effect = "Allow"

        Principal = { #quien puede hacer la accion (servicios o usuarios especificos)
          Service = "lambda.amazonaws.com"
          AWS     = "arn:aws:iam::000000000000:user/flocorp-admin"
        }
      }
    ]
  })
  tags = {
    Enviroment = "dev"
    Proyecto   = "flocorp"
  }
}

resource "aws_iam_policy" "politica-lambda-exec" {
  name        = "politica-flocorp-lambda"
  description = "permisos para gestion de dynamodb y s3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect = "Allow"

        Resources = [
          "arn:aws:dynamodb:*:*:table/flocorp-sesiones",
          "arn:aws:s3:::flocorp-bucket" #inexistente pero sirve para practicar
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "adjuntar-politica" {
  role       = aws_iam_role.flocorp-lambda-exec-role.name
  policy_arn = aws_iam_policy.politica-lambda-exec.arn

}