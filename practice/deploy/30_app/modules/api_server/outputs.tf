output "function_arn" {
  value       = module.lambda_fastapi_server.function_arn
  description = "ARN of the API Lambda function"
}

output "function_name" {
  value       = module.lambda_fastapi_server.function_name
  description = "Name of the API Lambda function"
}

output "invoke_arn" {
  value       = module.lambda_fastapi_server.invoke_arn
  description = "Invoke ARN for API Gateway integration"
}
