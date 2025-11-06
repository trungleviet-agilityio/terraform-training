# Outputs for the Core Layer

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "Current AWS account ID. [REMOTE STATE] Used by 20_infra for backend config."
}

output "state_backend_bucket_arn" {
  value       = module.state_backend.bucket_arn
  description = "ARN of the S3 bucket for Terraform state storage. [REMOTE STATE] Used by 20_infra for backend config."
}

output "state_backend_dynamodb_table_arn" {
  value       = module.state_backend.dynamodb_table_arn
  description = "ARN of the DynamoDB table for Terraform state locking. [REMOTE STATE] Used by 20_infra for backend config."
}

# ============================================================================
# General Use Outputs (Available for local use, not consumed via remote state)
# ============================================================================
output "region" {
  value       = data.aws_region.current.name
  description = "Current AWS region."
}

output "common_tags" {
  value       = local.common_tags
  description = "Common tags applied by core layer."
}

output "log_retention_days" {
  value       = module.log_retention.retention_days
  description = "Default CloudWatch log retention period in days."
}

output "state_backend_bucket_name" {
  value       = module.state_backend.bucket_name
  description = "Name of the S3 bucket for Terraform state storage."
}

output "state_backend_dynamodb_table_name" {
  value       = module.state_backend.dynamodb_table_name
  description = "Name of the DynamoDB table for Terraform state locking."
}
