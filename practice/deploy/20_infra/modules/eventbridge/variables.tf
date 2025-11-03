variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "schedule_name" {
  description = "Name of the schedule (without prefix)"
  type        = string
  default     = "cron-producer"
}

variable "schedule_expression" {
  description = "Schedule expression (cron or rate). Example: 'cron(0 12 * * ? *)' or 'rate(5 minutes)'"
  type        = string
  default     = "cron(0 12 * * ? *)"  # Daily at 12:00 PM UTC
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function (for IAM permission)"
  type        = string
}

variable "enabled" {
  description = "Whether the schedule is enabled"
  type        = bool
  default     = true
}

variable "description" {
  description = "Description of the schedule"
  type        = string
  default     = null
}

variable "input" {
  description = "JSON input to pass to the Lambda function"
  type        = string
  default     = "{}"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
