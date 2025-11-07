terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend configuration
  # Environment-specific values (bucket name) are provided via backend.tfvars
  # Usage: terraform init -backend-config=backend.tfvars

  # IMPORTANT: For FIRST deployment, you must bootstrap with local state first
  # See: shared/docs/remote-state.md for bootstrap instructions
  backend "s3" {
    key            = "core/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "tt-practice-tf-locks"
    # bucket is provided via backend.tfvars file
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

# Provider alias for us-east-1 (for API Gateway certificates)
# API Gateway custom domains require certificates in us-east-1 region
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
