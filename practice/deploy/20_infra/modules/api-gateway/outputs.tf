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

output "api_zone_id" {
  description = "API Gateway hosted zone ID (region-specific, for Route53 alias records)"
  value       = local.api_gateway_zone_id
}

# Custom Domain Outputs
output "custom_domain_name" {
  description = "Custom domain name (if configured). Null if custom domain not configured."
  value       = var.custom_domain_config != null ? aws_apigatewayv2_domain_name.custom[0].domain_name : null
}

output "custom_domain_arn" {
  description = "ARN of the custom domain name (if configured). Null if custom domain not configured."
  value       = var.custom_domain_config != null ? aws_apigatewayv2_domain_name.custom[0].arn : null
}

output "custom_domain_target" {
  description = "Target domain name for Route53 alias record (if configured). Null if custom domain not configured."
  value       = var.custom_domain_config != null ? aws_apigatewayv2_domain_name.custom[0].domain_name_configuration[0].target_domain_name : null
}

output "custom_domain_hosted_zone_id" {
  description = "Hosted zone ID for Route53 alias record (if configured). Null if custom domain not configured."
  value       = var.custom_domain_config != null ? aws_apigatewayv2_domain_name.custom[0].domain_name_configuration[0].hosted_zone_id : null
}
