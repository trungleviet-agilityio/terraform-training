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
