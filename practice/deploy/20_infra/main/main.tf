# Get the AWS account ID and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# API Gateway HTTP API
# Note: Requires Lambda function ARN/name from 30_app layer
# Set create_api_gateway = false if Lambda is not yet created
module "api_gateway" {
  count  = var.create_api_gateway && var.api_lambda_function_arn != "" ? 1 : 0
  source = "../modules/api-gateway"

  project_name          = var.project_name
  environment           = var.environment
  lambda_function_arn   = var.api_lambda_function_arn
  lambda_function_name  = var.api_lambda_function_name

  tags = local.common_tags
}

# SQS Queues (Main Queue + Dead Letter Queue)
module "sqs" {
  count  = var.create_sqs ? 1 : 0
  source = "../modules/sqs"

  project_name = var.project_name
  environment  = var.environment
  queue_name   = var.sqs_queue_name
  enable_dlq   = var.sqs_enable_dlq

  tags = local.common_tags
}

# EventBridge Schedule (Cron Job)
# Note: Requires Lambda function ARN/name from 30_app layer
# Set create_eventbridge_schedule = false if Lambda is not yet created
module "eventbridge_schedule" {
  count  = var.create_eventbridge_schedule && var.eventbridge_schedule_expression != "" && var.eventbridge_lambda_function_arn != "" ? 1 : 0
  source = "../modules/eventbridge"

  project_name         = var.project_name
  environment          = var.environment
  schedule_name        = var.eventbridge_schedule_name
  schedule_expression  = var.eventbridge_schedule_expression
  lambda_function_arn  = var.eventbridge_lambda_function_arn
  lambda_function_name = var.eventbridge_lambda_function_name

  tags = local.common_tags
}
