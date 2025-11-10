variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "package" {
  type = object({
    zip_path = string
    zip_hash = string
    lambda_layer_arn = optional(string)
  })
  description = "Package information containing zip_path, zip_hash, and optional lambda_layer_arn"
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the IAM execution role"
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue"
}

variable "handler" {
  type        = string
  description = "Lambda handler function name"
  default     = "worker.lambda_handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "python3.13"
}

variable "memory_size" {
  type        = number
  description = "Memory size in MB"
  default     = 128
}

variable "timeout" {
  type        = number
  description = "Timeout in seconds"
  default     = 60
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 14
}

variable "enabled" {
  type        = bool
  description = "Whether the event source mapping is enabled"
  default     = true
}

variable "batch_size" {
  type        = number
  description = "Maximum number of records per batch"
  default     = 10
}

variable "maximum_batching_window_in_seconds" {
  type        = number
  description = "Maximum batching window in seconds"
  default     = 0
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables"
  default     = {}
}

variable "layers" {
  type        = list(string)
  description = "Lambda layer ARNs"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply"
  default     = {}
}
