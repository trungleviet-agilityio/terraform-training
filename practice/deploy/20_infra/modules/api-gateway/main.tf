data "aws_region" "current" {}

locals {
  api_name = coalesce(var.api_name, "${var.project_name}-${var.environment}-api")

  # API Gateway HTTP API hosted zone IDs by region
  api_gateway_zone_ids = {
    "us-east-1"      = "Z1UJRXOUMOOFQ8"
    "us-west-1"      = "Z2F56UJP2H4LAZ"
    "ap-southeast-1" = "Z1D633PJN98FT9"
    "ap-southeast-2" = "Z2Y9QB7XY9KZ8X"
    # TODO: Add more regions as needed
  }

  api_gateway_zone_id = lookup(local.api_gateway_zone_ids, data.aws_region.current.name, null)
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "this" {
  name          = local.api_name
  protocol_type = "HTTP"
  description   = "HTTP API for ${var.project_name} ${var.environment} environment"

  # CORS configuration (if provided)
  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []
    content {
      allow_credentials = cors_configuration.value.allow_credentials
      allow_headers     = cors_configuration.value.allow_headers
      allow_methods     = cors_configuration.value.allow_methods
      allow_origins     = cors_configuration.value.allow_origins
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
    }
  }

  tags = var.tags
}


# API Gateway default stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  tags = var.tags
}


# Custom Domain Name (optional)
# Only created if custom_domain_config is provided
resource "aws_apigatewayv2_domain_name" "custom" {
  count = var.custom_domain_config != null ? 1 : 0

  domain_name = var.custom_domain_config.domain_name

  domain_name_configuration {
    certificate_arn = var.custom_domain_config.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = var.tags
}


# API Mapping - Maps API stage to custom domain
resource "aws_apigatewayv2_api_mapping" "custom" {
  count = var.custom_domain_config != null ? 1 : 0

  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.custom[0].id
  stage       = aws_apigatewayv2_stage.default.id
}


# Route53 A Record for Custom Domain (optional)
# Only created if custom_domain_config includes hosted_zone_id
resource "aws_route53_record" "custom_domain" {
  count = var.custom_domain_config != null && try(var.custom_domain_config.hosted_zone_id, null) != null ? 1 : 0

  zone_id = var.custom_domain_config.hosted_zone_id
  name    = var.custom_domain_config.domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.custom[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.custom[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
