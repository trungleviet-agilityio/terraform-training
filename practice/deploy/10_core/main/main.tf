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

# Store backend bucket name in AWS Secrets Manager for CI/CD workflows
# This allows workflows to retrieve bucket name without committing backend.tfvars
module "backend_bucket_secret" {
  source = "../modules/secrets"

  secret_name  = "backend-bucket"
  description  = "Terraform state backend S3 bucket name for CI/CD workflows"
  environment  = var.environment
  secret_string = jsonencode({
    bucket = module.state_backend.bucket_name
  })

  tags = local.common_tags
}

# Store Terraform variables in AWS Secrets Manager for CI/CD workflows
# These secrets contain only selected variables that vary by environment
# CI/CD workflows retrieve these and convert to TF_VAR_* environment variables
# Secret paths follow folder structure: /practice/{env}/{layer}/terraform-vars

# 10_core layer variables
# Contains: aws_region, project_name, environment, dns_config, use_us_east_1_certificate
# Secret path: /practice/{env}/10_core/terraform-vars
module "terraform_vars_10_core" {
  source = "../modules/secrets"

  secret_name  = "terraform-vars"
  layer        = "10_core"
  description  = "Terraform variables for 10_core layer (CI/CD use only)"
  environment  = var.environment
  secret_string = jsonencode({
    aws_region                = var.aws_region
    project_name              = var.project_name
    environment               = var.environment
    dns_config                = var.dns_config
    use_us_east_1_certificate = var.use_us_east_1_certificate
  })

  tags = local.common_tags
}

# 20_infra layer variables
# Contains: aws_region, project_name, environment (common vars)
# Note: github_oidc_config and dynamodb_tables should be added manually or via separate process
# as they are not available in 10_core layer. Use AWS Console or CLI to update the secret.
# Secret path: /practice/{env}/20_infra/terraform-vars
module "terraform_vars_20_infra" {
  source = "../modules/secrets"

  secret_name  = "terraform-vars"
  layer        = "20_infra"
  description  = "Terraform variables for 20_infra layer (CI/CD use only). Common vars set here, github_oidc_config and dynamodb_tables must be added separately via AWS Console/CLI."
  environment  = var.environment
  secret_string = jsonencode({
    aws_region   = var.aws_region
    project_name = var.project_name
    environment  = var.environment
  })

  tags = local.common_tags
}

# 30_app layer variables
# Contains: aws_region, project_name, environment (common vars)
# Note: eventbridge_schedule_expression and deploy_mode should be added manually or via separate process
# Use AWS Console or CLI to update the secret with layer-specific variables.
# Secret path: /practice/{env}/30_app/terraform-vars
module "terraform_vars_30_app" {
  source = "../modules/secrets"

  secret_name  = "terraform-vars"
  layer        = "30_app"
  description  = "Terraform variables for 30_app layer (CI/CD use only). Common vars set here, eventbridge_schedule_expression and deploy_mode must be added separately via AWS Console/CLI."
  environment  = var.environment
  secret_string = jsonencode({
    aws_region   = var.aws_region
    project_name = var.project_name
    environment  = var.environment
  })

  tags = local.common_tags
}
