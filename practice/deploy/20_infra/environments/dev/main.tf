# Import the main module
module "main" {
  source = "../../main"

  project_name             = var.project_name
  environment              = var.environment
  api_lambda_function_arn  = var.api_lambda_function_arn
  api_lambda_function_name = var.api_lambda_function_name
  create_api_gateway       = var.create_api_gateway
  sqs_queue_name           = var.sqs_queue_name
  sqs_enable_dlq           = var.sqs_enable_dlq
  create_sqs               = var.create_sqs
  tags                     = var.tags
}
