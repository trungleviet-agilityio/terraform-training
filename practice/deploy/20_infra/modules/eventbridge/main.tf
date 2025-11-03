locals {
  schedule_name_prefix = "${var.project_name}-${var.environment}"
  rule_name            = "${local.schedule_name_prefix}-${var.schedule_name}-schedule"
  role_name            = "${local.schedule_name_prefix}-${var.schedule_name}-eventbridge-role"
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

  tags = merge(
    var.tags,
    {
      Name    = local.role_name
      Purpose = "EventBridge Schedule IAM Role"
    }
  )
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

# EventBridge Schedule Rule
resource "aws_scheduler_schedule" "this" {
  name        = local.rule_name
  description = coalesce(var.description, "Schedule for ${var.schedule_name}")

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
