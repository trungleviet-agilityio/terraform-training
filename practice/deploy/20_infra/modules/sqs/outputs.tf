output "queue_url" {
  description = "URL of the main SQS queue"
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN of the main SQS queue"
  value       = aws_sqs_queue.main.arn
}

output "queue_name" {
  description = "Name of the main SQS queue"
  value       = aws_sqs_queue.main.name
}

output "dlq_url" {
  description = "URL of the Dead Letter Queue (null if DLQ not enabled)"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_arn" {
  description = "ARN of the Dead Letter Queue (null if DLQ not enabled)"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_name" {
  description = "Name of the Dead Letter Queue (null if DLQ not enabled)"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].name : null
}

output "dlq_alarm_arn" {
  description = "ARN of the CloudWatch alarm for DLQ messages (null if alarm not enabled)"
  value       = var.enable_dlq && var.enable_dlq_alarm ? aws_cloudwatch_metric_alarm.dlq_messages[0].arn : null
}

output "dlq_alarm_name" {
  description = "Name of the CloudWatch alarm for DLQ messages (null if alarm not enabled)"
  value       = var.enable_dlq && var.enable_dlq_alarm ? aws_cloudwatch_metric_alarm.dlq_messages[0].alarm_name : null
}
