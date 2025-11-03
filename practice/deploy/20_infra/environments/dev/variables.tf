# This file is used to define the variables for the development environment.

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "ap-southeast-1" # Singapore
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "tt-practice"
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "dev"
}

variable "api_lambda_function_arn" {
  description = "ARN of the Lambda function for API Gateway integration. Leave empty if Lambda not yet created."
  type        = string
  default     = ""
}

variable "api_lambda_function_name" {
  description = "Name of the Lambda function for API Gateway integration. Leave empty if Lambda not yet created."
  type        = string
  default     = ""
}

variable "create_api_gateway" {
  description = "Whether to create API Gateway. Set to false if Lambda is not yet created."
  type        = bool
  default     = true
}

variable "sqs_queue_name" {
  description = "Name of the main SQS queue (without prefix). Default: 'main'"
  type        = string
  default     = "main"
}

variable "sqs_enable_dlq" {
  description = "Whether to create a Dead Letter Queue for SQS. Default: true"
  type        = bool
  default     = true
}

variable "create_sqs" {
  description = "Whether to create SQS queues. Default: true"
  type        = bool
  default     = true
}

variable "eventbridge_schedule_name" {
  description = "Name of the EventBridge schedule (without prefix). Default: 'producer'"
  type        = string
  default     = "producer"
}

variable "eventbridge_schedule_expression" {
  description = "Schedule expression (cron or rate). Example: 'cron(0 12 * * ? *)' for daily at 12:00 UTC"
  type        = string
  default     = ""
}

variable "eventbridge_lambda_function_arn" {
  description = "ARN of the Lambda function for EventBridge schedule. Leave empty if Lambda not yet created."
  type        = string
  default     = ""
}

variable "eventbridge_lambda_function_name" {
  description = "Name of the Lambda function for EventBridge schedule. Leave empty if Lambda not yet created."
  type        = string
  default     = ""
}

variable "create_eventbridge_schedule" {
  description = "Whether to create EventBridge schedule. Set to false if Lambda is not yet created."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
