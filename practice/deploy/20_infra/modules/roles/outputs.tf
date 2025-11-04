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
