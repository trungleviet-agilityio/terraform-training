variable "project_name" {
  type        = string
  description = "Project name for resource naming."
}

variable "environment" {
  type        = string
  description = "Environment name, e.g., dev, stage, prod."
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to resources."
  default     = {}
}

variable "deploy_mode" {
  type        = string
  description = "Deployment mode for app functions: 'zip' or 'container'."
  default     = "zip"
  validation {
    condition     = contains(["zip", "container"], var.deploy_mode)
    error_message = "deploy_mode must be either 'zip' or 'container'."
  }
}
