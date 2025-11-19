output "function_arn" {
  value       = aws_lambda_function.cron_server.arn
  description = "ARN of the Lambda function"
}

output "function_name" {
  value       = aws_lambda_function.cron_server.function_name
  description = "Name of the Lambda function"
}
