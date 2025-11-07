variable "project_name" {
  type        = string
  description = "Project name for resource naming."

  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Environment name, e.g., dev, stage, prod."

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
