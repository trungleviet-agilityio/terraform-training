output "function_arn" {
  value       = aws_lambda_function.sqs_worker.arn
  description = "ARN of the Lambda function"
}

output "function_name" {
  value       = aws_lambda_function.sqs_worker.function_name
  description = "Name of the Lambda function"
}

output "event_source_mapping_id" {
  value       = aws_lambda_event_source_mapping.sqs_trigger.id
  description = "ID of the event source mapping"
}
