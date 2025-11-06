variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "package_zip_path" {
  type        = string
  description = "Path to the zip file containing Lambda code"
}

variable "package_zip_hash" {
  type        = string
  description = "Base64-encoded SHA256 hash of the zip file"
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the IAM execution role for the Lambda function"
}

variable "handler" {
  type        = string
  description = "Lambda handler function name"
  default     = "api_server.lambda_handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime (e.g., python3.13)"
  default     = "python3.13"
}

variable "memory_size" {
  type        = number
  description = "Amount of memory in MB for Lambda function"
  default     = 128
}

variable "timeout" {
  type        = number
  description = "Timeout in seconds for Lambda function"
  default     = 30
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 14
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for Lambda function"
  default     = {}
}

variable "layers" {
  type        = list(string)
  description = "List of Lambda layer ARNs to attach"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Lambda function"
  default     = {}
}
