terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend configuration
  backend "s3" {
    bucket  = "tt-practice-tf-state-<unique>"
    key     = "app/terraform.tfstate"
    region  = "ap-southeast-1" # Singapore
    encrypt = true
    # dynamodb_table = "tt-practice-tf-locks" # Consider using this for locking the state file
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
