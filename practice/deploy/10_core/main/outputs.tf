output "region" {
  value       = data.aws_region.current.name
  description = "Current AWS region."
}

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "Current AWS account ID."
}

output "common_tags" {
  value       = local.common_tags
  description = "Common tags applied by core layer."
}

output "log_retention_days" {
  value       = module.log_retention.retention_days
  description = "Default CloudWatch log retention period in days."
}

output "kms_key_arn" {
  value       = try(aws_kms_key.this[0].arn, null)
  description = "ARN of the optional KMS key. Null if not created."
}

output "kms_key_id" {
  value       = try(aws_kms_key.this[0].id, null)
  description = "ID of the optional KMS key. Null if not created."
}

output "kms_alias_arn" {
  value       = try(aws_kms_alias.this[0].arn, null)
  description = "ARN of the optional KMS alias. Null if not created."
}

output "state_backend_bucket_name" {
  value       = module.state_backend.bucket_name
  description = "Name of the S3 bucket for Terraform state storage."
}

output "state_backend_bucket_arn" {
  value       = module.state_backend.bucket_arn
  description = "ARN of the S3 bucket for Terraform state storage."
}

output "state_backend_dynamodb_table_name" {
  value       = module.state_backend.dynamodb_table_name
  description = "Name of the DynamoDB table for Terraform state locking."
}

output "state_backend_dynamodb_table_arn" {
  value       = module.state_backend.dynamodb_table_arn
  description = "ARN of the DynamoDB table for Terraform state locking."
}
