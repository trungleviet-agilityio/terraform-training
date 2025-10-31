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

output "sqs_queue_url" {
  value       = length(module.sqs) > 0 ? module.sqs[0].queue_url : null
  description = "URL of the main SQS queue. Null if not created."
}

output "sqs_queue_arn" {
  value       = length(module.sqs) > 0 ? module.sqs[0].queue_arn : null
  description = "ARN of the main SQS queue. Null if not created."
}

output "sqs_queue_name" {
  value       = length(module.sqs) > 0 ? module.sqs[0].queue_name : null
  description = "Name of the main SQS queue. Null if not created."
}

output "sqs_dlq_url" {
  value       = length(module.sqs) > 0 ? module.sqs[0].dlq_url : null
  description = "URL of the Dead Letter Queue. Null if not created or DLQ disabled."
}

output "sqs_dlq_arn" {
  value       = length(module.sqs) > 0 ? module.sqs[0].dlq_arn : null
  description = "ARN of the Dead Letter Queue. Null if not created or DLQ disabled."
}

output "sqs_dlq_name" {
  value       = length(module.sqs) > 0 ? module.sqs[0].dlq_name : null
  description = "Name of the Dead Letter Queue. Null if not created or DLQ disabled."
}
