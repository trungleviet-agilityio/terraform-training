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

output "sqs_queue_url" {
  value       = module.main.sqs_queue_url
  description = "URL of the main SQS queue."
}

output "sqs_queue_arn" {
  value       = module.main.sqs_queue_arn
  description = "ARN of the main SQS queue."
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

output "eventbridge_schedule_arn" {
  value       = module.main.eventbridge_schedule_arn
  description = "ARN of the EventBridge schedule."
}

output "eventbridge_schedule_name" {
  value       = module.main.eventbridge_schedule_name
  description = "Name of the EventBridge schedule."
}

output "eventbridge_schedule_state" {
  value       = module.main.eventbridge_schedule_state
  description = "State of the EventBridge schedule."
}

output "eventbridge_iam_role_arn" {
  value       = module.main.eventbridge_iam_role_arn
  description = "ARN of the IAM role used by EventBridge."
}

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
