output "function_arn" {
  value       = aws_lambda_function.fastapi_server.arn
  description = "ARN of the Lambda function"
}

output "function_name" {
  value       = aws_lambda_function.fastapi_server.function_name
  description = "Name of the Lambda function"
}

output "invoke_arn" {
  value       = aws_lambda_function.fastapi_server.invoke_arn
  description = "ARN to be used for invoking Lambda Function from API Gateway"
}
