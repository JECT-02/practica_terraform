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
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    sts = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "flocorp" {
  bucket = "flocorp-eventos-raw"
  tags = {
    Enviroment = "dev"
    Project    = "clickstream"
    Owner      = "data-engineering"
  }
}

resource "aws_s3_bucket_versioning" "versioning_flocorp" {
  bucket = aws_s3_bucket.flocorp.id
  versioning_configuration {
    status = "Enabled"
  }
}
