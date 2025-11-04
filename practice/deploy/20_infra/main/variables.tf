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

variable "api_lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function for API Gateway integration. Leave empty string if not yet created."
  default     = ""
}

variable "api_lambda_function_name" {
  type        = string
  description = "Name of the Lambda function for API Gateway integration. Leave empty string if not yet created."
  default     = ""
}

variable "create_api_gateway" {
  type        = bool
  description = "Whether to create API Gateway. Set to false if Lambda is not yet created."
  default     = true
}

variable "sqs_queue_name" {
  type        = string
  description = "Name of the main SQS queue (without prefix)."
  default     = "main"
}

variable "sqs_enable_dlq" {
  type        = bool
  description = "Whether to create a Dead Letter Queue for SQS."
  default     = true
}

variable "create_sqs" {
  type        = bool
  description = "Whether to create SQS queues."
  default     = true
}

variable "eventbridge_schedule_name" {
  type        = string
  description = "Name of the EventBridge schedule (without prefix)."
  default     = "producer"
}

variable "eventbridge_schedule_expression" {
  type        = string
  description = "Schedule expression (cron or rate). Example: 'cron(0 12 * * ? *)' for daily at 12:00 UTC. Leave empty if not creating schedule."
  default     = ""

  validation {
    condition     = var.eventbridge_schedule_expression == "" || can(regex("^(cron|rate)\\(.*\\)$", var.eventbridge_schedule_expression))
    error_message = "eventbridge_schedule_expression must be empty string or a valid cron/rate expression (e.g., 'cron(0 12 * * ? *)' or 'rate(1 hour)')."
  }
}

variable "eventbridge_lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function for EventBridge schedule. Leave empty string if not yet created."
  default     = ""
}

variable "eventbridge_lambda_function_name" {
  type        = string
  description = "Name of the Lambda function for EventBridge schedule. Leave empty string if not yet created."
  default     = ""
}

variable "create_eventbridge_schedule" {
  type        = bool
  description = "Whether to create EventBridge schedule. Set to false if Lambda is not yet created."
  default     = true
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
