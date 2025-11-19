output "schedule_arn" {
  description = "ARN of the EventBridge schedule"
  value       = aws_scheduler_schedule.this.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by EventBridge"
  value       = aws_iam_role.eventbridge.arn
}
