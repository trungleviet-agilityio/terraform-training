variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "project_name" {
  type        = string
  description = "Project name."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "deploy_mode" {
  type        = string
  description = "zip or container"
  default     = "zip"
}

variable "tags" {
  type        = map(string)
  default     = {}
}
