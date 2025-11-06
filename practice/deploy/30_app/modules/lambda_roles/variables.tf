variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, stage, prod)"
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue (for worker Lambda permissions)"
}

variable "dynamodb_table_arns" {
  type        = list(string)
  description = "List of DynamoDB table ARNs (for Lambda DynamoDB permissions)"
  default     = []
}

variable "enable_dynamodb_access" {
  type        = bool
  description = "Whether to grant DynamoDB access to Lambda roles"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to IAM roles"
  default     = {}
}
