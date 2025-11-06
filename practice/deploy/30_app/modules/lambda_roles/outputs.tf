output "api_lambda_role_arn" {
  value       = aws_iam_role.api_lambda_role.arn
  description = "ARN of the IAM role for API Lambda function"
}

output "cron_lambda_role_arn" {
  value       = aws_iam_role.cron_lambda_role.arn
  description = "ARN of the IAM role for Cron Lambda function"
}

output "worker_lambda_role_arn" {
  value       = aws_iam_role.worker_lambda_role.arn
  description = "ARN of the IAM role for Worker Lambda function"
}
