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

resource "aws_dynamodb_table" "flocorp-sesiones" {
  name         = "flocorp-sesiones"
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
    attribute_name = "expira_en"
    enabled        = true
  }
}