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
