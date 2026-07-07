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
    dynamodb = "http://localhost:4566"
  }
}

resource "aws_dynamodb_table" "flocorp-sessions" {
  name         = "flocorp-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  tags = {
    Name       = "flocorp-sessions"
    Enviroment = "dev"
    project    = "flocorp"
  }
}