locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge({
    Project   = var.project_name,
    Env       = var.environment,
    ManagedBy = "Terraform"
  }, var.tags)
}
