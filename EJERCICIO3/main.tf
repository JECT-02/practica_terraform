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
  skip_region_validation      = true
  skip_requesting_account_id  = true

  endpoints {
    sts = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "Ejercicio3" {
  bucket = "flocorp-eventos-raw"
  tags = {
    Enviroment = "dev"
    Project    = "clickstream"
    Owner      = "data-enginnering"
  }
}