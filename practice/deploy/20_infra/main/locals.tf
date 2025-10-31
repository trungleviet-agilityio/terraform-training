locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Standardized common tags applied to all resources
  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }, var.tags)
}
