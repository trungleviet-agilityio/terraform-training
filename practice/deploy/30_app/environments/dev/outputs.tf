# Outputs for the Dev Environment

output "account_id" {
  value       = module.main.account_id
  description = "AWS account id."
}

output "region" {
  value       = module.main.region
  description = "AWS region."
}

output "common_tags" {
  value       = module.main.common_tags
  description = "Common tags applied by app layer."
}

# Lambda function outputs (for reference/debugging only)
# Note: These outputs are NOT consumed by other layers. API Gateway and EventBridge integrations
# are created within the 30_app layer itself using the api_gateway_integration and eventbridge_target components.
output "api_lambda_function_arn" {
  value       = module.main.api_lambda_function_arn
  description = "ARN of the API Lambda function (for reference/debugging only)"
}

output "api_lambda_function_name" {
  value       = module.main.api_lambda_function_name
  description = "Name of the API Lambda function (for reference/debugging only)"
}

output "cron_lambda_function_arn" {
  value       = module.main.cron_lambda_function_arn
  description = "ARN of the Cron Lambda function (for reference/debugging only)"
}

output "cron_lambda_function_name" {
  value       = module.main.cron_lambda_function_name
  description = "Name of the Cron Lambda function (for reference/debugging only)"
}

output "worker_lambda_function_arn" {
  value       = module.main.worker_lambda_function_arn
  description = "ARN of the Worker Lambda function."
}

output "worker_lambda_function_name" {
  value       = module.main.worker_lambda_function_name
  description = "Name of the Worker Lambda function."
}
