module "lambda_sqs_worker" {
  source = "../../../components/lambda_sqs_worker"

  function_name      = var.function_name
  package_zip_path   = var.package.zip_path
  package_zip_hash   = var.package.zip_hash
  execution_role_arn = var.execution_role_arn
  sqs_queue_arn      = var.sqs_queue_arn
  handler            = var.handler
  runtime            = var.runtime
  memory_size        = var.memory_size
  timeout            = var.timeout
  log_retention_days = var.log_retention_days
  enabled            = var.enabled
  batch_size         = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds
  environment_variables = var.environment_variables
  layers             = var.layers
  tags               = var.tags
}
