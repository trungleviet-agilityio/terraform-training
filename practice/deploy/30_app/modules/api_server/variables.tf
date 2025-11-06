variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "package" {
  type = object({
    zip_path = string
    zip_hash = string
  })
  description = "Package information containing zip_path and zip_hash"
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the IAM execution role"
}

variable "handler" {
  type        = string
  description = "Lambda handler function name"
  default     = "api_server.lambda_handler"
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
  default     = 30
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 14
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
