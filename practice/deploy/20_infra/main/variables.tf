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

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to resources."
  default     = {}
}
