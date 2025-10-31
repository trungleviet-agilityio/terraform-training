output "kms_key_arn" {
  value       = try(aws_kms_key.this[0].arn, null)
  description = "ARN of the optional KMS key. Null if not created."
}

output "region" {
  value       = data.aws_region.current.name
  description = "Current AWS region."
}

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "Current AWS account ID."
}
