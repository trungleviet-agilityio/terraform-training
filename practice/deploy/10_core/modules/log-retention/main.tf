# CloudWatch Log Retention Configuration
# This module provides log retention settings that can be referenced by other modules
# Actual log groups are created by the services that use them (Lambda, API Gateway, etc.)

# No resources are created here - this is a configuration module
# Log retention is applied when log groups are created by individual services
# or managed via separate resources/data sources

# For reference: Valid retention values are:
# 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365, 400, 545, 731, 1827, 3653

locals {
  # Validate retention value (handled by variable validation)
  retention_days = var.log_retention_in_days
}
