# Outputs for Remote State Consumption

output "account_id" {
  value       = module.main.account_id
  description = "AWS account id."
}

output "state_backend_bucket_arn" {
  value       = module.main.state_backend_bucket_arn
  description = "ARN of the S3 bucket for Terraform state storage."
}

output "state_backend_dynamodb_table_arn" {
  value       = module.main.state_backend_dynamodb_table_arn
  description = "ARN of the DynamoDB table for Terraform state locking."
}

output "region" {
  value       = module.main.region
  description = "Current AWS region."
}

output "common_tags" {
  value       = module.main.common_tags
  description = "Common tags applied by core layer."
}
