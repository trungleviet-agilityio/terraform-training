# Outputs for the Dev Environment
# ===============================
# These outputs are consumed by other layers via terraform_remote_state
#
# Outputs marked with [REMOTE STATE] are consumed by other layers via terraform_remote_state

output "region" {
  value       = module.main.region
  description = "AWS region."
}

output "account_id" {
  value       = module.main.account_id
  description = "AWS account ID."
}

output "common_tags" {
  value       = module.main.common_tags
  description = "Common tags applied by infra layer."
}

output "api_gateway_id" {
  value       = module.main.api_gateway_id
  description = "API Gateway HTTP API ID."
}

output "api_gateway_endpoint" {
  value       = module.main.api_gateway_endpoint
  description = "API Gateway HTTP endpoint URL."
}

output "api_gateway_execution_arn" {
  value       = module.main.api_gateway_execution_arn
  description = "API Gateway execution ARN."
}

output "api_gateway_name" {
  value       = module.main.api_gateway_name
  description = "API Gateway name."
}

output "api_gateway_custom_domain_name" {
  value       = module.main.api_gateway_custom_domain_name
  description = "API Gateway custom domain name. Null if custom domain not configured."
}

output "api_gateway_custom_domain_arn" {
  value       = module.main.api_gateway_custom_domain_arn
  description = "API Gateway custom domain ARN. Null if custom domain not configured."
}

output "sqs_queue_url" {
  value       = module.main.sqs_queue_url
  description = "URL of the main SQS queue."
}

output "sqs_queue_arn" {
  value       = module.main.sqs_queue_arn
  description = "ARN of the main SQS queue. Used by 30_app layer via terraform_remote_state."
}

output "sqs_queue_name" {
  value       = module.main.sqs_queue_name
  description = "Name of the main SQS queue."
}

output "sqs_dlq_url" {
  value       = module.main.sqs_dlq_url
  description = "URL of the Dead Letter Queue."
}

output "sqs_dlq_arn" {
  value       = module.main.sqs_dlq_arn
  description = "ARN of the Dead Letter Queue."
}

output "sqs_dlq_name" {
  value       = module.main.sqs_dlq_name
  description = "Name of the Dead Letter Queue."
}

output "sqs_dlq_alarm_arn" {
  value       = module.main.sqs_dlq_alarm_arn
  description = "ARN of the CloudWatch alarm for DLQ messages."
}

output "sqs_dlq_alarm_name" {
  value       = module.main.sqs_dlq_alarm_name
  description = "Name of the CloudWatch alarm for DLQ messages."
}

output "dynamodb_table_names" {
  value       = module.main.dynamodb_table_names
  description = "Map of DynamoDB table names (key -> table name). [REMOTE STATE] Used by 30_app for Lambda environment variables."
}

output "dynamodb_table_arns" {
  value       = module.main.dynamodb_table_arns
  description = "Map of DynamoDB table ARNs (key -> table ARN). Used by 30_app layer via terraform_remote_state for Lambda IAM permissions."
}

# Lambda Role Outputs (for 30_app layer consumption)
output "lambda_api_role_arn" {
  value       = module.main.lambda_api_role_arn
  description = "ARN of the IAM role for API Lambda function. [REMOTE STATE] Used by 30_app for Lambda function creation."
}

output "lambda_api_role_name" {
  value       = module.main.lambda_api_role_name
  description = "Name of the IAM role for API Lambda function."
}

output "lambda_cron_role_arn" {
  value       = module.main.lambda_cron_role_arn
  description = "ARN of the IAM role for Cron Lambda function. [REMOTE STATE] Used by 30_app for Lambda function creation."
}

output "lambda_cron_role_name" {
  value       = module.main.lambda_cron_role_name
  description = "Name of the IAM role for Cron Lambda function."
}

output "lambda_worker_role_arn" {
  value       = module.main.lambda_worker_role_arn
  description = "ARN of the IAM role for Worker Lambda function. [REMOTE STATE] Used by 30_app for Lambda function creation."
}

output "lambda_worker_role_name" {
  value       = module.main.lambda_worker_role_name
  description = "Name of the IAM role for Worker Lambda function."
}

# ============================================================================
# CI/CD Outputs (Used by GitHub Actions workflows)
# ============================================================================
# OIDC Provider Outputs
output "oidc_provider_arn" {
  value       = module.main.oidc_provider_arn
  description = "ARN of the OIDC provider for GitHub Actions. Null if not created."
}

# GitHub Actions Role Outputs
output "terraform_plan_role_arn" {
  value       = module.main.terraform_plan_role_arn
  description = "ARN of the Terraform plan role for GitHub Actions. Use this for GitHub Secret AWS_ROLE_ARN in terraform-plan.yml workflow. Null if not created."
  sensitive   = false
}

output "terraform_apply_role_arn" {
  value       = module.main.terraform_apply_role_arn
  description = "ARN of the Terraform apply role for GitHub Actions. Use this for GitHub Secret AWS_ROLE_ARN in terraform-apply.yml workflow. Null if not created."
  sensitive   = false
}

output "terraform_plan_role_name" {
  value       = module.main.terraform_plan_role_name
  description = "Name of the Terraform plan role. Null if not created."
}

output "terraform_apply_role_name" {
  value       = module.main.terraform_apply_role_name
  description = "Name of the Terraform apply role. Null if not created."
}
