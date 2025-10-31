# SQS Queues Module

This module creates SQS queues for message queuing between Lambda functions.

## Resources

- Main SQS Queue (standard queue)
- Dead Letter Queue (DLQ) - optional
- Queue policies for send/receive permissions
- Redrive policy (sends failed messages to DLQ)

## Usage

```hcl
module "sqs" {
  source = "../modules/sqs"

  project_name = var.project_name
  environment  = var.environment
  queue_name   = "tasks"  # Optional: defaults to "main"

  # Optional: Customize queue settings
  message_retention_seconds  = 345600  # 4 days
  visibility_timeout_seconds = 30
  max_receive_count          = 3
  
  tags = var.tags
}
```

## Variables

- `project_name`: Project name for resource naming
- `environment`: Environment name
- `queue_name`: Name of the queue (default: "main")
- `enable_dlq`: Whether to create a Dead Letter Queue (default: true)
- `message_retention_seconds`: How long messages are retained (default: 4 days)
- `visibility_timeout_seconds`: Visibility timeout (default: 30 seconds)
- `receive_wait_time_seconds`: Long polling wait time (default: 0 = short polling)
- `max_receive_count`: Max times a message can be received before moving to DLQ (default: 3)
- `dlq_message_retention_seconds`: DLQ message retention (default: 14 days)
- `tags`: Tags to apply to resources

## Outputs

- `queue_url`: URL of the main queue
- `queue_arn`: ARN of the main queue
- `queue_name`: Name of the main queue
- `dlq_url`: URL of the DLQ (null if disabled)
- `dlq_arn`: ARN of the DLQ (null if disabled)
- `dlq_name`: Name of the DLQ (null if disabled)

## Queue Configuration

### Main Queue
- **Type**: Standard queue
- **Message Retention**: 4 days (configurable)
- **Visibility Timeout**: 30 seconds (configurable)
- **Polling**: Short polling (0 seconds wait time)
- **Redrive Policy**: Automatically moves failed messages to DLQ after `max_receive_count` attempts

### Dead Letter Queue
- **Type**: Standard queue
- **Message Retention**: 14 days (configurable)
- **Purpose**: Stores messages that failed processing

## IAM Permissions

The queue policies allow:
- **Send Message**: Any AWS service in the same account
- **Receive Message**: Lambda functions with event source mappings
- **Delete Message**: Lambda functions processing messages

## Usage with Lambda

### Producer Lambda (Sends Messages)
```hcl
# IAM policy for Lambda to send messages
resource "aws_iam_role_policy" "producer" {
  policy = jsonencode({
    Effect = "Allow"
    Action = ["sqs:SendMessage"]
    Resource = module.sqs.queue_arn
  })
}
```

### Consumer Lambda (Receives Messages)
```hcl
# Event source mapping (receives messages automatically)
resource "aws_lambda_event_source_mapping" "sqs_worker" {
  event_source_arn = module.sqs.queue_arn
  function_name    = aws_lambda_function.worker.arn
  batch_size       = 10
}
```

## Notes

- **Standard Queue**: Uses at-least-once delivery (messages may be delivered multiple times)
- **DLQ**: Automatically receives messages after `max_receive_count` failed processing attempts
- **Visibility Timeout**: How long a message is hidden after being received (should be >= Lambda timeout)
- **Long Polling**: Set `receive_wait_time_seconds = 20` for long polling (reduces API calls)

## Example: Custom Queue Configuration

```hcl
module "sqs_tasks" {
  source = "../modules/sqs"

  project_name               = var.project_name
  environment                = var.environment
  queue_name                 = "tasks"
  message_retention_seconds  = 604800  # 7 days
  visibility_timeout_seconds = 60    # 1 minute
  receive_wait_time_seconds  = 20    # Long polling
  max_receive_count          = 5      # More retries before DLQ
  enable_dlq                 = true

  tags = var.tags
}
```
