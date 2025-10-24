# Terraform Configuration
terraform {
  # Minimum Terraform version requirement
  required_version = "~> 1.6"
  
  # Required providers and their versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # S3 Backend Configuration with State Locking
  # This configuration stores Terraform state remotely in S3
  # and uses DynamoDB for state locking to prevent concurrent modifications
  backend "s3" {
    # ⚠️  IMPORTANT: S3 bucket names must be globally unique across ALL AWS accounts
    # ⚠️  If you get a "bucket already exists" error, change the bucket name below
    # ⚠️  Use a unique prefix like your name, company, or random string
    bucket         = "my-terraform-remote-backend-bucket-trungle"  # S3 bucket for state storage (MUST be globally unique)
    key            = "my-project/state.tfstate"            # State file path in bucket
    region         = "us-east-1"                           # AWS region (bucket is in us-east-1)
    dynamodb_table = "terraform-state-lock"                # DynamoDB table for locking
    encrypt        = true                                  # Encrypt state at rest
  }
}

# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"  # Default AWS region for all resources
}
