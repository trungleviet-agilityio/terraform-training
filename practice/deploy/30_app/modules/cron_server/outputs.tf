output "function_arn" {
  value       = module.lambda_cron_server.function_arn
  description = "ARN of the Cron Lambda function"
}

output "function_name" {
  value       = module.lambda_cron_server.function_name
  description = "Name of the Cron Lambda function"
}
