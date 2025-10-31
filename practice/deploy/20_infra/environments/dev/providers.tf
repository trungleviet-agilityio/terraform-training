terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend configuration
  # Using the same state backend bucket created by 10_core layer
  backend "s3" {
    bucket         = "tt-practice-tf-state-dev-057336397237"
    key            = "infra/terraform.tfstate"
    region         = "ap-southeast-1" # Singapore
    encrypt        = true
    dynamodb_table = "tt-practice-tf-locks"
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Environment = var.environment
        Project     = var.project_name
        ManagedBy   = "Terraform"
      },
      var.tags
    )
  }
}
