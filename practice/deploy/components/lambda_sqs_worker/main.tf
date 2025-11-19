# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda function for SQS worker
resource "aws_lambda_function" "sqs_worker" {
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

# Event source mapping for SQS queue
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.sqs_worker.arn
  enabled          = var.enabled

  # SQS-specific configuration
  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds

  depends_on = [
    aws_lambda_function.sqs_worker
  ]
}
