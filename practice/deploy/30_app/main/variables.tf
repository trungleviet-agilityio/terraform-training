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
  description = "ARN of the SQS queue from 20_infra layer (for worker Lambda event source mapping)"
}

# Lambda Role ARNs (from 20_infra layer)
variable "lambda_api_role_arn" {
  type        = string
  description = "ARN of the IAM role for API Lambda function from 20_infra layer"
}

variable "lambda_cron_role_arn" {
  type        = string
  description = "ARN of the IAM role for Cron Lambda function from 20_infra layer"
}

variable "lambda_worker_role_arn" {
  type        = string
  description = "ARN of the IAM role for Worker Lambda function from 20_infra layer"
}

# API Gateway Integration Variables (from 20_infra layer)
variable "api_gateway_id" {
  type        = string
  description = "API Gateway HTTP API ID from 20_infra layer"
  default     = ""
}

variable "api_gateway_execution_arn" {
  type        = string
  description = "API Gateway execution ARN from 20_infra layer"
  default     = ""
}

# EventBridge Integration Variables
variable "eventbridge_schedule_expression" {
  type        = string
  description = "EventBridge schedule expression (cron or rate). Configure in terraform.tfvars."
  default     = ""
}

# DynamoDB Table Names (from 20_infra layer)
variable "dynamodb_table_names" {
  type        = map(string)
  description = "Map of DynamoDB table names (key -> table name) from 20_infra layer. Used to set Lambda environment variables."
  default     = {}
}
