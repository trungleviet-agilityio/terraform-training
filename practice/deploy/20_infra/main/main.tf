# Get the AWS account ID and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# API Gateway HTTP API
# Only created if Lambda ARN is provided (from 30_app layer)
module "api_gateway" {
  count  = var.api_lambda_function_arn != "" ? 1 : 0
  source = "../modules/api-gateway"

  project_name         = var.project_name
  environment          = var.environment
  lambda_function_arn  = var.api_lambda_function_arn
  lambda_function_name = var.api_lambda_function_name

  tags = local.common_tags
}

# SQS Queues (Main Queue + Dead Letter Queue)
# Always created for practice project - modules use defaults
module "sqs" {
  source = "../modules/sqs"

  project_name = var.project_name
  environment  = var.environment
  # Let module use defaults: queue_name = "main", enable_dlq = true

  tags = local.common_tags
}

# EventBridge Schedule (Cron Job)
# Only created if schedule expression and Lambda ARN are provided
module "eventbridge_schedule" {
  count  = var.eventbridge_schedule_expression != "" && var.eventbridge_lambda_function_arn != "" ? 1 : 0
  source = "../modules/eventbridge"

  project_name         = var.project_name
  environment          = var.environment
  schedule_expression  = var.eventbridge_schedule_expression
  lambda_function_arn  = var.eventbridge_lambda_function_arn
  lambda_function_name = var.eventbridge_lambda_function_name
  # Let module use default: schedule_name = "producer"

  tags = local.common_tags
}

# OIDC Provider for GitHub Actions
module "oidc_provider" {
  count  = var.github_oidc_config.create_oidc ? 1 : 0
  source = "../modules/oidc-provider"

  name = "oidc-provider-github-actions-${var.environment}"
  tags = local.common_tags
}

# Terraform Policies for GitHub Actions
module "terraform_policies" {
  count  = var.github_oidc_config.create_policies ? 1 : 0
  source = "../modules/policies"

  policy_name_prefix = "github-actions-terraform-${var.environment}"
  state_bucket_arn   = var.backend_config.bucket_arn
  dynamodb_table_arn = var.backend_config.table_arn
  account_id         = var.backend_config.account_id
  region             = data.aws_region.current.id
  tags               = local.common_tags
}

# GitHub Actions IAM Roles
module "github_actions_roles" {
  count  = var.github_oidc_config.create_oidc && var.github_oidc_config.create_policies && (var.github_oidc_config.create_plan_role || var.github_oidc_config.create_apply_role) ? 1 : 0
  source = "../modules/roles"

  oidc_provider_arn           = module.oidc_provider[0].oidc_provider_arn
  github_organization         = var.github_oidc_config.organization
  github_repository           = var.github_oidc_config.repository
  create_terraform_plan_role  = var.github_oidc_config.create_plan_role
  create_terraform_apply_role = var.github_oidc_config.create_apply_role
  terraform_plan_role_name    = "${var.project_name}-${var.environment}-terraform-plan"
  terraform_apply_role_name   = "${var.project_name}-${var.environment}-terraform-apply"
  terraform_plan_policy_arn   = module.terraform_policies[0].terraform_plan_policy_arn
  terraform_apply_policy_arn  = module.terraform_policies[0].terraform_apply_policy_arn
  allowed_branches            = var.github_oidc_config.allowed_branches

  tags = local.common_tags
}
