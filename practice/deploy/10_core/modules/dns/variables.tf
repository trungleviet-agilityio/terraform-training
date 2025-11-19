variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the hosted zone (e.g., example.com)"
  type        = string
}

variable "api_gateway_endpoint" {
  description = "API Gateway endpoint domain name (for A record alias). Leave empty to skip API Gateway DNS record."
  type        = string
  default     = ""
}

variable "api_gateway_zone_id" {
  description = "API Gateway hosted zone ID (required if api_gateway_endpoint is provided)"
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "Subdomain for API Gateway (e.g., 'api' creates api.example.com). Leave empty to use root domain."
  type        = string
  default     = "api"
}

variable "cname_records" {
  description = "Map of CNAME records to create (key = subdomain, value = target)"
  type        = map(string)
  default     = {}
}

variable "a_records" {
  description = "Map of A records to create (key = subdomain, value = list of IP addresses)"
  type        = map(list(string))
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
