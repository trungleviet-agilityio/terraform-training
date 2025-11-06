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
  value       = length(module.api_gateway) > 0 ? module.api_gateway[0].api_id : null
  description = "API Gateway HTTP API ID. Null if not created."
}

output "api_gateway_endpoint" {
  value       = length(module.api_gateway) > 0 ? module.api_gateway[0].api_endpoint : null
  description = "API Gateway HTTP endpoint URL. Null if not created."
}

output "api_gateway_execution_arn" {
  value       = length(module.api_gateway) > 0 ? module.api_gateway[0].api_execution_arn : null
  description = "API Gateway execution ARN. Null if not created."
}

output "api_gateway_name" {
  value       = length(module.api_gateway) > 0 ? module.api_gateway[0].api_name : null
  description = "API Gateway name. Null if not created."
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

output "eventbridge_schedule_arn" {
  value       = length(module.eventbridge_schedule) > 0 ? module.eventbridge_schedule[0].schedule_arn : null
  description = "ARN of the EventBridge schedule. Null if not created."
}

output "eventbridge_schedule_name" {
  value       = length(module.eventbridge_schedule) > 0 ? module.eventbridge_schedule[0].schedule_name : null
  description = "Name of the EventBridge schedule. Null if not created."
}

output "eventbridge_schedule_state" {
  value       = length(module.eventbridge_schedule) > 0 ? module.eventbridge_schedule[0].schedule_state : null
  description = "State of the EventBridge schedule. Null if not created."
}

output "eventbridge_iam_role_arn" {
  value       = length(module.eventbridge_schedule) > 0 ? module.eventbridge_schedule[0].iam_role_arn : null
  description = "ARN of the IAM role used by EventBridge. Null if not created."
}

# OIDC Provider Outputs
output "oidc_provider_arn" {
  value       = length(module.oidc_provider) > 0 ? module.oidc_provider[0].oidc_provider_arn : null
  description = "ARN of the OIDC provider for GitHub Actions. Null if not created."
}

# GitHub Actions Role Outputs
output "terraform_plan_role_arn" {
  value       = length(module.github_actions_roles) > 0 ? module.github_actions_roles[0].terraform_plan_role_arn : null
  description = "ARN of the Terraform plan role for GitHub Actions. Use this for GitHub Secret AWS_ROLE_ARN in terraform-plan.yml workflow. Null if not created."
}

output "terraform_apply_role_arn" {
  value       = length(module.github_actions_roles) > 0 ? module.github_actions_roles[0].terraform_apply_role_arn : null
  description = "ARN of the Terraform apply role for GitHub Actions. Use this for GitHub Secret AWS_ROLE_ARN in terraform-apply.yml workflow. Null if not created."
}

output "terraform_plan_role_name" {
  value       = length(module.github_actions_roles) > 0 ? module.github_actions_roles[0].terraform_plan_role_name : null
  description = "Name of the Terraform plan role. Null if not created."
}

output "terraform_apply_role_name" {
  value       = length(module.github_actions_roles) > 0 ? module.github_actions_roles[0].terraform_apply_role_name : null
  description = "Name of the Terraform apply role. Null if not created."
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
