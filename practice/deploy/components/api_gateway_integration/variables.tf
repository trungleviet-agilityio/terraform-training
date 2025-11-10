variable "api_gateway_id" {
  description = "API Gateway HTTP API ID"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN (for Lambda permission source_arn)"
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

variable "routes" {
  description = "List of API Gateway routes to create. Each route should have 'path' and 'method' keys. Example: [{path = \"/users\", method = \"GET\"}, {path = \"/users\", method = \"POST\"}]"
  type = list(object({
    path   = string
    method = string
  }))
  default = []
}
