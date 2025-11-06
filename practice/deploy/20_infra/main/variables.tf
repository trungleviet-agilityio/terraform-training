variable "project_name" {
  type        = string
  description = "Project name for resource naming."

  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Environment name, e.g., dev, stage, prod."

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

# Lambda integration variables (from 30_app layer)
# Only needed if you plan to integrate Lambda with API Gateway or EventBridge
variable "api_lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function for API Gateway integration. Leave empty if not yet created."
  default     = ""
}

variable "api_lambda_function_name" {
  type        = string
  description = "Name of the Lambda function for API Gateway integration. Leave empty if not yet created."
  default     = ""
}

variable "eventbridge_lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function for EventBridge schedule. Leave empty if not yet created."
  default     = ""
}

variable "eventbridge_lambda_function_name" {
  type        = string
  description = "Name of the Lambda function for EventBridge schedule. Leave empty if not yet created."
  default     = ""
}

variable "eventbridge_schedule_expression" {
  type        = string
  description = "Schedule expression (cron or rate). Leave empty to skip EventBridge creation."
  default     = ""

  validation {
    condition     = var.eventbridge_schedule_expression == "" || can(regex("^(cron|rate)\\(.*\\)$", var.eventbridge_schedule_expression))
    error_message = "eventbridge_schedule_expression must be empty string or a valid cron/rate expression."
  }
}

# GitHub OIDC Configuration (grouped to reduce duplication)
variable "github_oidc_config" {
  type = object({
    organization      = string
    repository        = string
    create_oidc       = bool
    create_policies   = bool
    create_plan_role  = bool
    create_apply_role = bool
    allowed_branches  = optional(list(string))
  })
  description = "GitHub OIDC configuration for GitHub Actions authentication."
  default = {
    organization      = ""
    repository        = ""
    create_oidc       = false
    create_policies   = false
    create_plan_role  = false
    create_apply_role = false
    allowed_branches  = null
  }
}

# Backend Configuration (from 10_core layer outputs, grouped)
variable "backend_config" {
  type = object({
    bucket_arn = string
    table_arn  = string
    account_id = string
  })
  description = "Terraform state backend configuration from 10_core layer."
  default = {
    bucket_arn = ""
    table_arn  = ""
    account_id = ""
  }
}

# DynamoDB Tables Configuration
variable "dynamodb_tables" {
  description = "Map of DynamoDB table configurations. See modules/dynamodb/README.md for configuration options."
  type = map(object({
    partition_key = string
    sort_key      = optional(string)
    attribute_types = optional(map(string), {})
    type          = optional(string, "key-value")
    billing_mode  = optional(string, "PAY_PER_REQUEST")
    enable_ttl    = optional(bool, false)
    ttl_attribute = optional(string, "ttl")
    enable_point_in_time_recovery = optional(bool, false)
    enable_stream = optional(bool, false)
    stream_view_type = optional(string, "NEW_AND_OLD_IMAGES")
    kms_key_id    = optional(string)
    purpose       = optional(string, "Application Data Storage")
  }))
  default = {}
}
