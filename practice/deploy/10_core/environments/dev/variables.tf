# Variables for the dev environment
# ============================================
# ROOT MODULE VARIABLES
# These variables are passed to the main module
# ============================================

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
