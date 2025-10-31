locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Standardized common tags applied to all resources
  # Base tags include: Project, Environment, ManagedBy
  # Additional tags can be merged via var.tags
  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }, var.tags)
}
