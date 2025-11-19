output "terraform_plan_role_arn" {
  value       = var.create_terraform_plan_role ? aws_iam_role.terraform_plan[0].arn : null
  description = "ARN of the Terraform plan role (for GitHub Secret AWS_ROLE_ARN)."
}

output "terraform_apply_role_arn" {
  value       = var.create_terraform_apply_role ? aws_iam_role.terraform_apply[0].arn : null
  description = "ARN of the Terraform apply role (for apply workflow)."
}

output "terraform_plan_role_name" {
  value       = var.create_terraform_plan_role ? aws_iam_role.terraform_plan[0].name : null
  description = "Name of the Terraform plan role."
}

output "terraform_apply_role_name" {
  value       = var.create_terraform_apply_role ? aws_iam_role.terraform_apply[0].name : null
  description = "Name of the Terraform apply role."
}

# Lambda Role Outputs
output "lambda_api_role_arn" {
  value       = var.create_lambda_roles ? aws_iam_role.api_lambda_role[0].arn : null
  description = "ARN of the IAM role for API Lambda function"
}

output "lambda_api_role_name" {
  value       = var.create_lambda_roles ? aws_iam_role.api_lambda_role[0].name : null
  description = "Name of the IAM role for API Lambda function"
}

output "lambda_cron_role_arn" {
  value       = var.create_lambda_roles ? aws_iam_role.cron_lambda_role[0].arn : null
  description = "ARN of the IAM role for Cron Lambda function"
}

output "lambda_cron_role_name" {
  value       = var.create_lambda_roles ? aws_iam_role.cron_lambda_role[0].name : null
  description = "Name of the IAM role for Cron Lambda function"
}

output "lambda_worker_role_arn" {
  value       = var.create_lambda_roles ? aws_iam_role.worker_lambda_role[0].arn : null
  description = "ARN of the IAM role for Worker Lambda function"
}

output "lambda_worker_role_name" {
  value       = var.create_lambda_roles ? aws_iam_role.worker_lambda_role[0].name : null
  description = "Name of the IAM role for Worker Lambda function"
}
