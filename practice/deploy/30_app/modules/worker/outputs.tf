output "function_arn" {
  value       = module.lambda_sqs_worker.function_arn
  description = "ARN of the Worker Lambda function"
}

output "function_name" {
  value       = module.lambda_sqs_worker.function_name
  description = "Name of the Worker Lambda function"
}

output "event_source_mapping_id" {
  value       = module.lambda_sqs_worker.event_source_mapping_id
  description = "ID of the SQS event source mapping"
}
