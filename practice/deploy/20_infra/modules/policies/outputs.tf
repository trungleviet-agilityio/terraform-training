output "terraform_state_access_policy_arn" {
  value       = length(aws_iam_policy.terraform_state_access) > 0 ? aws_iam_policy.terraform_state_access[0].arn : null
  description = "ARN of the Terraform state access policy. Null if GitHub Actions policies not created."
}

output "terraform_resource_creation_policy_arn" {
  value       = length(aws_iam_policy.terraform_resource_creation) > 0 ? aws_iam_policy.terraform_resource_creation[0].arn : null
  description = "ARN of the Terraform resource creation policy. Null if GitHub Actions policies not created."
}

output "terraform_plan_policy_arn" {
  value       = length(aws_iam_policy.terraform_plan) > 0 ? aws_iam_policy.terraform_plan[0].arn : null
  description = "ARN of the Terraform plan policy (read-only + state access). Null if GitHub Actions policies not created."
}

output "terraform_apply_policy_arn" {
  value       = length(aws_iam_policy.terraform_apply) > 0 ? aws_iam_policy.terraform_apply[0].arn : null
  description = "ARN of the Terraform apply policy (full access + state access). Null if GitHub Actions policies not created."
}

output "terraform_state_access_policy_name" {
  value       = length(aws_iam_policy.terraform_state_access) > 0 ? aws_iam_policy.terraform_state_access[0].name : null
  description = "Name of the Terraform state access policy. Null if GitHub Actions policies not created."
}

output "terraform_resource_creation_policy_name" {
  value       = length(aws_iam_policy.terraform_resource_creation) > 0 ? aws_iam_policy.terraform_resource_creation[0].name : null
  description = "Name of the Terraform resource creation policy. Null if GitHub Actions policies not created."
}

output "terraform_plan_policy_name" {
  value       = length(aws_iam_policy.terraform_plan) > 0 ? aws_iam_policy.terraform_plan[0].name : null
  description = "Name of the Terraform plan policy. Null if GitHub Actions policies not created."
}

output "terraform_apply_policy_name" {
  value       = length(aws_iam_policy.terraform_apply) > 0 ? aws_iam_policy.terraform_apply[0].name : null
  description = "Name of the Terraform apply policy. Null if GitHub Actions policies not created."
}

# Lambda Policy Outputs
output "lambda_dynamodb_access_policy_arn" {
  value       = length(aws_iam_policy.lambda_dynamodb_access) > 0 ? aws_iam_policy.lambda_dynamodb_access[0].arn : null
  description = "ARN of the DynamoDB access policy for Lambda functions. Null if no DynamoDB tables configured."
}

output "lambda_sqs_access_policy_arn" {
  value       = length(aws_iam_policy.lambda_sqs_access) > 0 ? aws_iam_policy.lambda_sqs_access[0].arn : null
  description = "ARN of the SQS access policy for Lambda functions. Null if no SQS queue configured."
}
