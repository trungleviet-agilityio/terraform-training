output "schedule_arn" {
  description = "ARN of the EventBridge schedule"
  value       = aws_scheduler_schedule.this.arn
}

output "schedule_name" {
  description = "Name of the EventBridge schedule"
  value       = aws_scheduler_schedule.this.name
}

output "schedule_state" {
  description = "State of the schedule (ENABLED or DISABLED)"
  value       = aws_scheduler_schedule.this.state
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by EventBridge"
  value       = aws_iam_role.eventbridge.arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by EventBridge"
  value       = aws_iam_role.eventbridge.name
}
