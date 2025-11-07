# Outputs for the Infrastructure Layer

# ============================================================================
# General Use Outputs (Available for local use, not consumed via remote state)
# ============================================================================
output "region" {
  value       = data.aws_region.current.id
  description = "Current AWS region."
}

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "Current AWS account ID."
}

output "common_tags" {
  value       = local.common_tags
  description = "Common tags applied by infra layer."
}

output "api_gateway_id" {
  value       = module.api_gateway.api_id
  description = "API Gateway HTTP API ID. [REMOTE STATE] Used by 30_app for API Gateway integration."
}

output "api_gateway_endpoint" {
  value       = module.api_gateway.api_endpoint
  description = "API Gateway HTTP endpoint URL."
}

output "api_gateway_execution_arn" {
  value       = module.api_gateway.api_execution_arn
  description = "API Gateway execution ARN. [REMOTE STATE] Used by 30_app for API Gateway integration."
}

output "api_gateway_name" {
  value       = module.api_gateway.api_name
  description = "API Gateway name."
}

# Custom Domain Outputs
output "api_gateway_custom_domain_name" {
  value       = module.api_gateway.custom_domain_name
  description = "API Gateway custom domain name. Null if custom domain not configured."
}

output "api_gateway_custom_domain_arn" {
  value       = module.api_gateway.custom_domain_arn
  description = "API Gateway custom domain ARN. Null if custom domain not configured."
}

output "sqs_queue_arn" {
  value       = module.sqs.queue_arn
  description = "ARN of the main SQS queue. [REMOTE STATE] Used by 30_app for worker Lambda event source mapping."
}

output "sqs_queue_url" {
  value       = module.sqs.queue_url
  description = "URL of the main SQS queue."
}

output "sqs_queue_name" {
  value       = module.sqs.queue_name
  description = "Name of the main SQS queue."
}

output "sqs_dlq_url" {
  value       = module.sqs.dlq_url
  description = "URL of the Dead Letter Queue. Null if DLQ disabled."
}

output "sqs_dlq_arn" {
  value       = module.sqs.dlq_arn
  description = "ARN of the Dead Letter Queue. Null if DLQ disabled."
}

output "sqs_dlq_name" {
  value       = module.sqs.dlq_name
  description = "Name of the Dead Letter Queue. Null if DLQ disabled."
}

output "sqs_dlq_alarm_arn" {
  value       = module.sqs.dlq_alarm_arn
  description = "ARN of the CloudWatch alarm for DLQ messages. Null if alarm disabled."
}

output "sqs_dlq_alarm_name" {
  value       = module.sqs.dlq_alarm_name
  description = "Name of the CloudWatch alarm for DLQ messages. Null if alarm disabled."
}

# EventBridge schedule creation moved to 30_app layer
# Schedule expression configuration remains in terraform.tfvars

# OIDC Provider Outputs
output "oidc_provider_arn" {
  value       = length(module.oidc_provider) > 0 ? module.oidc_provider[0].oidc_provider_arn : null
  description = "ARN of the OIDC provider for GitHub Actions. Null if not created."
}

# DynamoDB Outputs
output "dynamodb_table_names" {
  value       = length(module.dynamodb) > 0 ? module.dynamodb[0].table_names : {}
  description = "Map of DynamoDB table names (key -> table name). Empty map if no tables configured."
}

output "dynamodb_table_arns" {
  value       = length(module.dynamodb) > 0 ? module.dynamodb[0].table_arns : {}
  description = "Map of DynamoDB table ARNs (key -> table ARN). Empty map if no tables configured. [REMOTE STATE] Used by 30_app for Lambda IAM permissions."
}

output "dynamodb_table_stream_arns" {
  value       = length(module.dynamodb) > 0 ? module.dynamodb[0].table_stream_arns : {}
  description = "Map of DynamoDB table stream ARNs (key -> stream ARN, null if stream not enabled). Empty map if no tables configured."
}

# Lambda Role Outputs
output "lambda_api_role_arn" {
  value       = module.iam_roles.lambda_api_role_arn
  description = "ARN of the IAM role for API Lambda function. [REMOTE STATE] Used by 30_app for Lambda function creation."
}

output "lambda_api_role_name" {
  value       = module.iam_roles.lambda_api_role_name
  description = "Name of the IAM role for API Lambda function."
}

output "lambda_cron_role_arn" {
  value       = module.iam_roles.lambda_cron_role_arn
  description = "ARN of the IAM role for Cron Lambda function. [REMOTE STATE] Used by 30_app for Lambda function creation."
}

output "lambda_cron_role_name" {
  value       = module.iam_roles.lambda_cron_role_name
  description = "Name of the IAM role for Cron Lambda function."
}

output "lambda_worker_role_arn" {
  value       = module.iam_roles.lambda_worker_role_arn
  description = "ARN of the IAM role for Worker Lambda function. [REMOTE STATE] Used by 30_app for Lambda function creation."
}

output "lambda_worker_role_name" {
  value       = module.iam_roles.lambda_worker_role_name
  description = "Name of the IAM role for Worker Lambda function."
}

# GitHub Actions Role Outputs
output "terraform_plan_role_arn" {
  value       = module.iam_roles.terraform_plan_role_arn
  description = "ARN of the Terraform plan role for GitHub Actions. Use this for GitHub Secret AWS_ROLE_ARN in terraform-plan.yml workflow. Null if not created."
}

output "terraform_apply_role_arn" {
  value       = module.iam_roles.terraform_apply_role_arn
  description = "ARN of the Terraform apply role for GitHub Actions. Use this for GitHub Secret AWS_ROLE_ARN in terraform-apply.yml workflow. Null if not created."
}

output "terraform_plan_role_name" {
  value       = module.iam_roles.terraform_plan_role_name
  description = "Name of the Terraform plan role. Null if not created."
}

output "terraform_apply_role_name" {
  value       = module.iam_roles.terraform_apply_role_name
  description = "Name of the Terraform apply role. Null if not created."
}
