locals {
  queue_name_prefix = "${var.project_name}-${var.environment}"
  main_queue_name   = "${local.queue_name_prefix}-${var.queue_name}-queue"
  dlq_name          = "${local.queue_name_prefix}-${var.queue_name}-dlq"
}

# Dead Letter Queue (optional)
resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0
  
  name                      = local.dlq_name
  message_retention_seconds = var.dlq_message_retention_seconds

  tags = merge(
    var.tags,
    {
      Name        = local.dlq_name
      Purpose     = "Dead Letter Queue"
      QueueType   = "DLQ"
    }
  )
}

# Main SQS Queue
resource "aws_sqs_queue" "main" {
  name                      = local.main_queue_name
  message_retention_seconds = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # Redrive policy to send failed messages to DLQ
  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = merge(
    var.tags,
    {
      Name        = local.main_queue_name
      Purpose     = "Main Queue"
      QueueType   = "Standard"
    }
  )
}

# Queue policy for main queue (allows Lambda, API Gateway, EventBridge to send messages)
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.main.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Queue policy for DLQ (allows Lambda to send failed messages)
resource "aws_sqs_queue_policy" "dlq" {
  count = var.enable_dlq ? 1 : 0
  
  queue_url = aws_sqs_queue.dlq[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.dlq[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Data source for account ID
data "aws_caller_identity" "current" {}
