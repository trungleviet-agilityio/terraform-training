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

# Lambda function outputs for integration with 20_infra layer
# [REMOTE STATE] These outputs are consumed by 20_infra layer via terraform_remote_state
output "api_lambda_function_arn" {
  value       = module.main.api_lambda_function_arn
  description = "ARN of the API Lambda function (for API Gateway integration). [REMOTE STATE] Used by 20_infra for API Gateway integration."
}

output "api_lambda_function_name" {
  value       = module.main.api_lambda_function_name
  description = "Name of the API Lambda function. [REMOTE STATE] Used by 20_infra for API Gateway integration."
}

output "cron_lambda_function_arn" {
  value       = module.main.cron_lambda_function_arn
  description = "ARN of the Cron Lambda function (for EventBridge integration). [REMOTE STATE] Used by 20_infra for EventBridge integration."
}

output "cron_lambda_function_name" {
  value       = module.main.cron_lambda_function_name
  description = "Name of the Cron Lambda function. [REMOTE STATE] Used by 20_infra for EventBridge integration."
}

output "worker_lambda_function_arn" {
  value       = module.main.worker_lambda_function_arn
  description = "ARN of the Worker Lambda function."
}

output "worker_lambda_function_name" {
  value       = module.main.worker_lambda_function_name
  description = "Name of the Worker Lambda function."
}
