output "api_id" {
  description = "API Gateway HTTP API ID"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "API Gateway HTTP endpoint URL"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "api_stage_id" {
  description = "API Gateway default stage ID"
  value       = aws_apigatewayv2_stage.default.id
}

output "api_name" {
  description = "API Gateway name"
  value       = aws_apigatewayv2_api.this.name
}
