# Variables for the dev environment

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "ap-southeast-1" # Singapore

  validation {
    condition     = length(var.aws_region) > 0
    error_message = "AWS region must be a non-empty string."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "tt-practice"

  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must be a non-empty string."
  }
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

# Optional: To easy switch between zip and container deployment in the future
variable "deploy_mode" {
  description = "Deployment mode for Lambda functions: 'zip' or 'container'"
  type        = string
  default     = "zip"

  validation {
    condition     = contains(["zip", "container"], var.deploy_mode)
    error_message = "deploy_mode must be either 'zip' or 'container'."
  }
}

variable "eventbridge_schedule_expression" {
  description = "Schedule expression (cron or rate) for EventBridge. Example: 'cron(0 12 * * ? *)' or 'rate(5 minutes)'. Leave empty to skip EventBridge schedule creation."
  type        = string
  default     = ""

  validation {
    condition     = var.eventbridge_schedule_expression == "" || can(regex("^(cron|rate)\\(.*\\)$", var.eventbridge_schedule_expression))
    error_message = "eventbridge_schedule_expression must be empty string or a valid cron/rate expression."
  }
}
