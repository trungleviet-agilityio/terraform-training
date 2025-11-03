terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend configuration
  # NOTE: Update bucket name after state backend is created (see bootstrap-state.md)
  # Temporarily disabled to bootstrap state backend - uncomment after first apply
  backend "s3" {
    bucket         = "tt-practice-tf-state-dev-057336397237"
    key            = "core/terraform.tfstate"
    region         = "ap-southeast-1" # Singapore
    encrypt        = true
    dynamodb_table = "tt-practice-tf-locks"
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
