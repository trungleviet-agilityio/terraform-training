# Get AWS account ID for constructing bucket name
data "aws_caller_identity" "current" {}

# Get remote state from 20_infra layer
data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket  = "tt-practice-tf-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key     = "infra/terraform.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

# Import the main module
module "main" {
  source = "../../main"

  project_name  = var.project_name
  environment   = var.environment
  deploy_mode   = var.deploy_mode
  sqs_queue_arn = try(data.terraform_remote_state.infra.outputs.sqs_queue_arn, "")

  # Lambda Role ARNs (from 20_infra layer)
  lambda_api_role_arn    = try(data.terraform_remote_state.infra.outputs.lambda_api_role_arn, "")
  lambda_cron_role_arn   = try(data.terraform_remote_state.infra.outputs.lambda_cron_role_arn, "")
  lambda_worker_role_arn = try(data.terraform_remote_state.infra.outputs.lambda_worker_role_arn, "")

  # API Gateway Integration (from 20_infra layer)
  api_gateway_id            = try(data.terraform_remote_state.infra.outputs.api_gateway_id, "")
  api_gateway_execution_arn = try(data.terraform_remote_state.infra.outputs.api_gateway_execution_arn, "")

  # DynamoDB Table Names (from 20_infra layer)
  dynamodb_table_names = try(data.terraform_remote_state.infra.outputs.dynamodb_table_names, {})

  # EventBridge Integration - schedule created in 30_app layer
  # Schedule expression can be configured in terraform.tfvars
  eventbridge_schedule_expression = var.eventbridge_schedule_expression
}
