variable "project_name" {
  type        = string
  description = "Project name for resource naming."
}

variable "environment" {
  type        = string
  description = "Environment name, e.g., dev, stage, prod."
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
  description = "Name of the main SQS queue (without prefix). Default: 'main'"
  default     = "main"
}

variable "sqs_enable_dlq" {
  type        = bool
  description = "Whether to create a Dead Letter Queue for SQS. Default: true"
  default     = true
}

variable "create_sqs" {
  type        = bool
  description = "Whether to create SQS queues. Default: true"
  default     = true
}

variable "eventbridge_schedule_name" {
  type        = string
  description = "Name of the EventBridge schedule (without prefix). Default: 'producer'"
  default     = "producer"
}

variable "eventbridge_schedule_expression" {
  type        = string
  description = "Schedule expression (cron or rate). Example: 'cron(0 12 * * ? *)' for daily at 12:00 UTC"
  default     = ""
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

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to resources."
  default     = {}
}
