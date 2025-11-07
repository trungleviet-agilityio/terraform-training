# Get the AWS account ID and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# API Gateway HTTP API
# Always created - integrations will be added in 30_app layer
module "api_gateway" {
  source = "../modules/api-gateway"

  project_name         = var.project_name
  environment          = var.environment
  custom_domain_config = var.custom_domain_config

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

# EventBridge Schedule creation moved to 30_app layer to break circular dependency
# Schedule expression can still be configured in terraform.tfvars and passed to 30_app

# OIDC Provider for GitHub Actions
module "oidc_provider" {
  count  = var.github_oidc_config.create_oidc ? 1 : 0
  source = "../modules/oidc-provider"

  name = "oidc-provider-github-actions-${var.environment}"
  tags = local.common_tags
}

# DynamoDB Tables (optional, only created if tables are configured)
module "dynamodb" {
  count  = length(var.dynamodb_tables) > 0 ? 1 : 0
  source = "../modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
  tables       = var.dynamodb_tables

  tags = local.common_tags
}

# IAM Policies (consolidated: includes GitHub Actions and Lambda policies)
# Always create policies module for Lambda policies, conditionally create GitHub Actions policies
module "iam_policies" {
  source = "../modules/policies"

  # GitHub Actions policy variables (optional)
  policy_name_prefix = var.github_oidc_config.create_policies ? "github-actions-terraform-${var.environment}" : ""
  state_bucket_arn   = var.backend_config.bucket_arn != "" ? var.backend_config.bucket_arn : ""
  dynamodb_table_arn = var.backend_config.table_arn != "" ? var.backend_config.table_arn : ""
  account_id         = var.backend_config.account_id != "" ? var.backend_config.account_id : ""
  region             = data.aws_region.current.id

  # Lambda policy variables (always create)
  project_name        = var.project_name
  environment         = var.environment
  dynamodb_table_arns = length(module.dynamodb) > 0 ? values(module.dynamodb[0].table_arns) : []
  sqs_queue_arn       = module.sqs.queue_arn
  enable_sqs_policy   = true # SQS queue is always created

  tags = local.common_tags
}

# IAM Roles (includes GitHub Actions and Lambda roles)
# Always create roles module for Lambda roles, conditionally create GitHub Actions roles
module "iam_roles" {
  source = "../modules/roles"

  # GitHub Actions role variables (optional)
  oidc_provider_arn           = length(module.oidc_provider) > 0 ? module.oidc_provider[0].oidc_provider_arn : ""
  github_organization         = var.github_oidc_config.organization
  github_repository           = var.github_oidc_config.repository
  create_terraform_plan_role  = var.github_oidc_config.create_oidc && var.github_oidc_config.create_policies && var.github_oidc_config.create_plan_role
  create_terraform_apply_role = var.github_oidc_config.create_oidc && var.github_oidc_config.create_policies && var.github_oidc_config.create_apply_role
  terraform_plan_role_name    = "${var.project_name}-${var.environment}-terraform-plan"
  terraform_apply_role_name   = "${var.project_name}-${var.environment}-terraform-apply"
  terraform_plan_policy_arn   = var.github_oidc_config.create_policies ? module.iam_policies.terraform_plan_policy_arn : ""
  terraform_apply_policy_arn  = var.github_oidc_config.create_policies ? module.iam_policies.terraform_apply_policy_arn : ""
  allowed_branches            = var.github_oidc_config.allowed_branches

  # Lambda role variables (always create)
  create_lambda_roles    = true
  project_name           = var.project_name
  environment            = var.environment
  enable_dynamodb_policy = length(var.dynamodb_tables) > 0
  enable_sqs_policy      = true # SQS queue is always created
  lambda_policies = {
    lambda_dynamodb_access_policy_arn = module.iam_policies.lambda_dynamodb_access_policy_arn
    lambda_sqs_access_policy_arn      = module.iam_policies.lambda_sqs_access_policy_arn
  }

  tags = local.common_tags
}
