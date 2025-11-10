# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda function for FastAPI server
resource "aws_lambda_function" "fastapi_server" {
  filename         = var.package_zip_path
  function_name    = var.function_name
  role             = var.execution_role_arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = var.package_zip_hash

  # Optional configuration
  memory_size = var.memory_size
  timeout     = var.timeout

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # Layers (optional)
  layers = var.layers

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# Lambda Function URL (optional)
resource "aws_lambda_function_url" "this" {
  count = var.enable_function_url ? 1 : 0

  function_name      = aws_lambda_function.fastapi_server.function_name
  authorization_type = var.function_url_authorization_type

  cors {
    allow_credentials = var.function_url_cors.allow_credentials
    allow_headers    = var.function_url_cors.allow_headers
    allow_methods    = var.function_url_cors.allow_methods
    allow_origins    = var.function_url_cors.allow_origins
    expose_headers   = var.function_url_cors.expose_headers
    max_age          = var.function_url_cors.max_age
  }
}
