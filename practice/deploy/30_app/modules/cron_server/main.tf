module "lambda_cron_server" {
  source = "../../../components/lambda_cron_server"

  function_name      = var.function_name
  package_zip_path   = var.package.zip_path
  package_zip_hash   = var.package.zip_hash
  execution_role_arn = var.execution_role_arn
  handler            = var.handler
  runtime            = var.runtime
  memory_size        = var.memory_size
  timeout            = var.timeout
  log_retention_days = var.log_retention_days
  environment_variables = var.environment_variables
  layers             = var.layers
  tags               = var.tags
}
