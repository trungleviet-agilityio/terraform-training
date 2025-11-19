locals {
  role_name = "${var.project_name}-${var.environment}-eventbridge-target-role"
}

# IAM role for EventBridge to invoke Lambda
resource "aws_iam_role" "eventbridge" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM policy allowing EventBridge to invoke Lambda
resource "aws_iam_role_policy" "invoke_lambda" {
  name = "${local.role_name}-invoke-lambda"
  role = aws_iam_role.eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = var.lambda_function_arn
      }
    ]
  })
}

# EventBridge Schedule with Target
# Creates the schedule with Lambda target in 30_app layer
# Note: This resource depends on the Lambda function existing (enforced via depends_on in calling module)
resource "aws_scheduler_schedule" "this" {
  name        = var.schedule_name
  description = "Schedule with Lambda target (managed by 30_app layer)"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.schedule_expression

  state = var.enabled ? "ENABLED" : "DISABLED"

  target {
    arn      = var.lambda_function_arn
    role_arn = aws_iam_role.eventbridge.arn

    input = var.input
  }
}
