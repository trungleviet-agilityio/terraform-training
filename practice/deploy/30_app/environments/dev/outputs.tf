output "account_id" {
  value       = module.main.account_id
  description = "AWS account id."
}

output "region" {
  value       = module.main.region
  description = "AWS region."
}

output "common_tags" {
  value       = module.main.common_tags
  description = "Common tags applied by app layer."
}
