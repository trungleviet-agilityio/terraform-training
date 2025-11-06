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

variable "deploy_mode" {
  type        = string
  description = "Deployment mode for app functions: 'zip' or 'container'."
  default     = "zip"

  validation {
    condition     = contains(["zip", "container"], var.deploy_mode)
    error_message = "deploy_mode must be either 'zip' or 'container'."
  }
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue from 20_infra layer"
}

variable "dynamodb_table_arns" {
  type        = list(string)
  description = "List of DynamoDB table ARNs from 20_infra layer"
  default     = []
}
