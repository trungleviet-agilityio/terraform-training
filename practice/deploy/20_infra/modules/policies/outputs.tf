output "terraform_state_access_policy_arn" {
  value       = aws_iam_policy.terraform_state_access.arn
  description = "ARN of the Terraform state access policy."
}

output "terraform_resource_creation_policy_arn" {
  value       = aws_iam_policy.terraform_resource_creation.arn
  description = "ARN of the Terraform resource creation policy."
}

output "terraform_plan_policy_arn" {
  value       = aws_iam_policy.terraform_plan.arn
  description = "ARN of the Terraform plan policy (read-only + state access)."
}

output "terraform_apply_policy_arn" {
  value       = aws_iam_policy.terraform_apply.arn
  description = "ARN of the Terraform apply policy (full access + state access)."
}

output "terraform_state_access_policy_name" {
  value       = aws_iam_policy.terraform_state_access.name
  description = "Name of the Terraform state access policy."
}

output "terraform_resource_creation_policy_name" {
  value       = aws_iam_policy.terraform_resource_creation.name
  description = "Name of the Terraform resource creation policy."
}

output "terraform_plan_policy_name" {
  value       = aws_iam_policy.terraform_plan.name
  description = "Name of the Terraform plan policy."
}

output "terraform_apply_policy_name" {
  value       = aws_iam_policy.terraform_apply.name
  description = "Name of the Terraform apply policy."
}
