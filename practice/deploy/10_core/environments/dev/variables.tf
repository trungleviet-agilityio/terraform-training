# Variables for the dev environment

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "ap-southeast-1" # Singapore

  validation {
    condition     = length(var.aws_region) > 0
    error_message = "AWS region must be a non-empty string."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "tt-practice"

  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must be a non-empty string."
  }
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

# DNS Configuration (Route53)
variable "dns_config" {
  description = "DNS configuration for Route53 hosted zone. Leave domain_name empty to skip DNS setup."
  type = object({
    domain_name          = string
    api_gateway_endpoint = optional(string, "")
    api_gateway_zone_id  = optional(string, "")
    api_subdomain        = optional(string, "api")
    cname_records        = optional(map(string), {})
    a_records            = optional(map(list(string)), {})
  })
  default = {
    domain_name          = ""
    api_gateway_endpoint = ""
    api_gateway_zone_id  = ""
    api_subdomain        = "api"
    cname_records        = {}
    a_records            = {}
  }
}

# Certificate Region Configuration
variable "use_us_east_1_certificate" {
  description = "Create ACM certificate in us-east-1 region (required for API Gateway custom domains). Defaults to false (uses default provider region)."
  type        = bool
  default     = false
}
