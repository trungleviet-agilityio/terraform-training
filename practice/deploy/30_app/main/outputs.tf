# Outputs for the Application Layer

output "region" {
  value       = data.aws_region.current.name
  description = "Current AWS region."
}

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "Current AWS account ID."
}

output "common_tags" {
  value       = local.common_tags
  description = "Common tags applied by app layer."
}

# Lambda function outputs (for reference/debugging only)
# Note: These outputs are NOT consumed by other layers. API Gateway and EventBridge integrations
# are created within the 30_app layer itself using the api_gateway_integration and eventbridge_target components.
output "api_lambda_function_arn" {
  value       = module.api_server.function_arn
  description = "ARN of the API Lambda function (for reference/debugging only)"
}

output "api_lambda_function_name" {
  value       = module.api_server.function_name
  description = "Name of the API Lambda function"
}

output "api_lambda_invoke_arn" {
  value       = module.api_server.invoke_arn
  description = "Invoke ARN of the API Lambda function (for API Gateway integration)"
}

output "cron_lambda_function_arn" {
  value       = module.cron_server.function_arn
  description = "ARN of the Cron Lambda function (for EventBridge integration)"
}

output "cron_lambda_function_name" {
  value       = module.cron_server.function_name
  description = "Name of the Cron Lambda function"
}

output "worker_lambda_function_arn" {
  value       = module.worker.function_arn
  description = "ARN of the Worker Lambda function"
}

output "worker_lambda_function_name" {
  value       = module.worker.function_name
  description = "Name of the Worker Lambda function"
}
