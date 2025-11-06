# Get the AWS account ID and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Package Lambda source code
module "runtime_code_modules" {
  source = "../modules/runtime_code_modules"

  # Convert relative path to absolute path
  source_base_path = abspath("${path.root}/../../../../src/lambda")
  output_dir       = abspath("${path.root}/../../../../out")
}

# Create IAM roles for Lambda functions
module "lambda_roles" {
  source = "../modules/lambda_roles"

  project_name        = var.project_name
  environment         = var.environment
  sqs_queue_arn       = var.sqs_queue_arn
  dynamodb_table_arns = var.dynamodb_table_arns
  tags                = local.common_tags
}

# API Server Lambda (FastAPI)
module "api_server" {
  source = "../modules/api_server"

  function_name      = "${local.name_prefix}-api-server"
  package            = module.runtime_code_modules.api_server
  execution_role_arn = module.lambda_roles.api_lambda_role_arn
  handler            = "api_server.lambda_handler"
  runtime            = "python3.13"
  memory_size        = 128
  timeout            = 30
  tags               = local.common_tags
}

# Cron Server Lambda
module "cron_server" {
  source = "../modules/cron_server"

  function_name      = "${local.name_prefix}-cron-server"
  package            = module.runtime_code_modules.cron_server
  execution_role_arn = module.lambda_roles.cron_lambda_role_arn
  handler            = "cron_server.lambda_handler"
  runtime            = "python3.13"
  memory_size        = 128
  timeout            = 60
  tags               = local.common_tags
}

# Worker Lambda (SQS)
module "worker" {
  source = "../modules/worker"

  function_name      = "${local.name_prefix}-worker"
  package            = module.runtime_code_modules.worker
  execution_role_arn = module.lambda_roles.worker_lambda_role_arn
  sqs_queue_arn      = var.sqs_queue_arn
  handler            = "worker.lambda_handler"
  runtime            = "python3.13"
  memory_size        = 128
  timeout            = 60
  tags               = local.common_tags
}
