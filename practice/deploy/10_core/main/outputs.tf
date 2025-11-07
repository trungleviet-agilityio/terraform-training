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

# DNS Outputs
# Handle both default provider and us-east-1 provider modules
output "dns_hosted_zone_id" {
  value       = length(module.dns) > 0 ? module.dns[0].hosted_zone_id : (length(module.dns_us_east_1) > 0 ? module.dns_us_east_1[0].hosted_zone_id : null)
  description = "ID of the Route53 hosted zone. Null if DNS not configured."
}

output "dns_hosted_zone_name" {
  value       = length(module.dns) > 0 ? module.dns[0].hosted_zone_name : (length(module.dns_us_east_1) > 0 ? module.dns_us_east_1[0].hosted_zone_name : null)
  description = "Name of the Route53 hosted zone. Null if DNS not configured."
}

output "dns_name_servers" {
  value       = length(module.dns) > 0 ? module.dns[0].name_servers : (length(module.dns_us_east_1) > 0 ? module.dns_us_east_1[0].name_servers : null)
  description = "Name servers for the hosted zone (configure at domain registrar). Null if DNS not configured."
}

output "dns_hosted_zone_arn" {
  value       = length(module.dns) > 0 ? module.dns[0].hosted_zone_arn : (length(module.dns_us_east_1) > 0 ? module.dns_us_east_1[0].hosted_zone_arn : null)
  description = "ARN of the Route53 hosted zone. Null if DNS not configured."
}

output "dns_certificate_arn" {
  value       = length(module.dns) > 0 ? module.dns[0].certificate_arn : (length(module.dns_us_east_1) > 0 ? module.dns_us_east_1[0].certificate_arn : null)
  description = "ARN of the ACM certificate (wildcard certificate). Null if DNS not configured. Note: For API Gateway, certificate must be in us-east-1 (set use_us_east_1_certificate = true)."
}

output "dns_certificate_domain" {
  value       = length(module.dns) > 0 ? module.dns[0].certificate_domain : (length(module.dns_us_east_1) > 0 ? module.dns_us_east_1[0].certificate_domain : null)
  description = "Primary domain name of the certificate. Null if DNS not configured."
}
