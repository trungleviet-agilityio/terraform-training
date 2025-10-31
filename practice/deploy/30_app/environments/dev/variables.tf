# This file is used to define the variables for the development environment.

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "ap-southeast-1" # Singapore
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "tt-practice"
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
