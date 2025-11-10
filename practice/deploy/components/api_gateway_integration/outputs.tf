output "integration_id" {
  description = "ID of the API Gateway integration"
  value       = aws_apigatewayv2_integration.lambda.id
}

output "route_id" {
  description = "ID of the API Gateway route"
  value       = aws_apigatewayv2_route.default.id
}
