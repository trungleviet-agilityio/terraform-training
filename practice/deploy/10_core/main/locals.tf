locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Standardized common tags applied to all resources
  # Generated from project_name and environment only
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
