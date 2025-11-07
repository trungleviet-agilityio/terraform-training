variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
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

# Custom Domain Configuration (optional)
variable "custom_domain_config" {
  description = "Custom domain configuration for API Gateway. Leave null to use default endpoint."
  type = object({
    certificate_arn = string           # ACM certificate ARN (must be in us-east-1 for API Gateway)
    domain_name     = string           # Custom domain name (e.g., api.dev.example.com)
    hosted_zone_id  = optional(string) # Route53 hosted zone ID (optional, will create A record if provided)
  })
  default = null
}
