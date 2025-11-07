/***
Main Module for the Core Layer

This module is responsible for creating the core infrastructure for the project.

Resources:
- S3 Bucket (Terraform state backend)
- DynamoDB Table (Terraform state locking)
- CloudWatch Log Retention Configuration

Note: DynamoDB table here is for Terraform state locking, NOT application data.
Application DynamoDB tables should be created in 20_infra (shared) or 30_app (app-specific).
*/


data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# Create Terraform state backend (S3 bucket + DynamoDB table)
module "state_backend" {
  source = "../modules/s3"

  project_name  = var.project_name
  environment   = var.environment
  unique_suffix = data.aws_caller_identity.current.account_id # Use account ID for uniqueness

  tags = local.common_tags
}

# CloudWatch Log Retention Configuration
# Uses module default for log_retention_in_days (14 days)
module "log_retention" {
  source = "../modules/log-retention"

  tags = local.common_tags
}

# DNS (Route53) Configuration
# Only created if domain_name is provided
# Uses default provider (Singapore) for practice mode
module "dns" {
  count  = var.dns_config.domain_name != "" && !var.use_us_east_1_certificate ? 1 : 0
  source = "../modules/dns"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.dns_config.domain_name

  tags = local.common_tags
}

# DNS (Route53) Configuration with us-east-1 certificate
# Only created if domain_name is provided AND use_us_east_1_certificate is true
# Uses us-east-1 provider for API Gateway certificates
module "dns_us_east_1" {
  count  = var.dns_config.domain_name != "" && var.use_us_east_1_certificate ? 1 : 0
  source = "../modules/dns"

  providers = {
    aws = aws.us_east_1
  }

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.dns_config.domain_name

  tags = local.common_tags
}
