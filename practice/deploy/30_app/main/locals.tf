locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Standardized common tags applied to all resources
  # Generated from project_name and environment only
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # DynamoDB table names from environment variables
  # Map table keys to environment variable names
  lambda_environment_variables = {
    USER_DATA_TABLE_NAME = try(var.dynamodb_table_names["user-data"], "")
    EVENTS_TABLE_NAME    = try(var.dynamodb_table_names["events"], "")
  }
}
