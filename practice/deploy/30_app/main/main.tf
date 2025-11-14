/***
Main Module for the Application Layer

This module is responsible for creating the application for the project.

Resources:
- Lambda Functions
- API Gateway Integration
- EventBridge Target
*/

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Package Lambda source code
module "runtime_code_modules" {
  source = "../modules/runtime_code_modules"

  # Convert relative path to absolute path
  source_base_path = abspath("${path.root}/../../../../src/lambda")
  output_dir       = abspath("${path.root}/../../../../out")
}


# API Server Lambda (FastAPI)
module "api_server" {
  source = "../modules/api_server"

  function_name         = "${local.name_prefix}-api-server"
  package               = module.runtime_code_modules.api_server
  execution_role_arn    = var.lambda_api_role_arn
  handler               = "api_server.lambda_handler"
  runtime               = "python3.13"
  memory_size           = 128
  timeout               = 30
  environment_variables = local.lambda_environment_variables
  layers                = compact([
    module.runtime_code_modules.practice_util.lambda_layer_arn,
    try(module.runtime_code_modules.api_server.lambda_layer_arn, null)
  ])
  tags                  = local.common_tags
}


# Cron Server Lambda
module "cron_server" {
  source = "../modules/cron_server"

  function_name         = "${local.name_prefix}-cron-server"
  package               = module.runtime_code_modules.cron_server
  execution_role_arn    = var.lambda_cron_role_arn
  handler               = "cron_server.lambda_handler"
  runtime               = "python3.13"
  memory_size           = 128
  timeout               = 60
  environment_variables = local.lambda_environment_variables
  layers                = compact([
    module.runtime_code_modules.practice_util.lambda_layer_arn,
    try(module.runtime_code_modules.cron_server.lambda_layer_arn, null)
  ])
  tags                  = local.common_tags
}


# Worker Lambda (SQS)
module "worker" {
  source = "../modules/worker"

  function_name         = "${local.name_prefix}-worker"
  package               = module.runtime_code_modules.worker
  execution_role_arn    = var.lambda_worker_role_arn
  sqs_queue_arn         = var.sqs_queue_arn
  handler               = "worker.lambda_handler"
  runtime               = "python3.13"
  memory_size           = 128
  timeout               = 60
  environment_variables = local.lambda_environment_variables
  layers                = compact([
    module.runtime_code_modules.practice_util.lambda_layer_arn,
    try(module.runtime_code_modules.worker.lambda_layer_arn, null)
  ])
  tags                  = local.common_tags
}


# API Gateway Integration (connects API Gateway from 20_infra to API Lambda)
# Explicitly depends on api_server module to ensure Lambda function exists before creating integration
module "api_gateway_integration" {
  count  = var.api_gateway_id != "" && var.api_gateway_execution_arn != "" ? 1 : 0
  source = "../../components/api_gateway_integration"

  api_gateway_id            = var.api_gateway_id
  api_gateway_execution_arn = var.api_gateway_execution_arn
  lambda_function_arn       = module.api_server.function_arn
  lambda_function_name      = module.api_server.function_name

  routes = [
    { path = "/users", method = "GET" },
    { path = "/users", method = "POST" },
    { path = "/events", method = "GET" },
    { path = "/events", method = "POST" },
  ]

  depends_on = [
    module.api_server
  ]
}


# EventBridge Target (creates schedule with Lambda target)
# Explicitly depends on cron_server module to ensure Lambda function exists before creating schedule
module "eventbridge_target" {
  count  = var.eventbridge_schedule_expression != "" ? 1 : 0
  source = "../../components/eventbridge_target"

  project_name         = var.project_name
  environment          = var.environment
  schedule_name        = "${var.project_name}-${var.environment}-cron-producer-schedule"
  schedule_expression  = var.eventbridge_schedule_expression
  lambda_function_arn  = module.cron_server.function_arn
  lambda_function_name = module.cron_server.function_name

  tags = local.common_tags

  depends_on = [
    module.cron_server
  ]
}
