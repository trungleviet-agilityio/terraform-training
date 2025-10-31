/***
Main Module for the Core Layer

This module is responsible for creating the core infrastructure for the project.

Resources:
- S3 Bucket (Terraform state backend)
- DynamoDB Table (Terraform state locking)
- CloudWatch Log Retention Configuration
- Optional: KMS Key
- Optional: KMS Alias

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
  unique_suffix = data.aws_caller_identity.current.account_id  # Use account ID for uniqueness

  tags = local.common_tags
}

# CloudWatch Log Retention Configuration
module "log_retention" {
  source = "../modules/log-retention"

  log_retention_in_days = var.log_retention_in_days
  tags                  = local.common_tags
}

# Optional KMS CMK for encryption
resource "aws_kms_key" "this" {
  count                   = var.create_kms ? 1 : 0
  description             = "${var.project_name} CMK for encryption (${var.environment})"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-kms"
    }
  )
}

resource "aws_kms_alias" "this" {
  count         = var.create_kms ? 1 : 0
  name          = var.kms_alias
  target_key_id = aws_kms_key.this[0].key_id
}
