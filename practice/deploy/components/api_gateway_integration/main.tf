# API Gateway integration with Lambda
# Note: This resource depends on the Lambda function existing (enforced via depends_on in calling module)
resource "aws_apigatewayv2_integration" "lambda" {
  api_id = var.api_gateway_id

  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = var.lambda_function_arn
  payload_format_version = "2.0"
}

# API Gateway route - default catch-all route
resource "aws_apigatewayv2_route" "default" {
  api_id    = var.api_gateway_id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# API Gateway routes - specific routes for /users and /events
resource "aws_apigatewayv2_route" "routes" {
  for_each = {
    for route in var.routes : "${route.method} ${route.path}" => route
  }

  api_id    = var.api_gateway_id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Lambda permission to allow API Gateway to invoke the function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
