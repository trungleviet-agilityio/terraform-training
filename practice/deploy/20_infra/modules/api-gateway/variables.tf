variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to integrate with API Gateway"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function (for invoke permission)"
  type        = string
}

variable "api_name" {
  description = "Name of the API Gateway (defaults to project_name-environment-api)"
  type        = string
  default     = null
}

variable "cors_configuration" {
  description = "CORS configuration for the API Gateway"
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["*"])
    allow_origins     = optional(list(string), ["*"])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 86400)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
