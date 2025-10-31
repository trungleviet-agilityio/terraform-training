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

variable "log_retention_in_days" {
  description = "Default log retention period in days for created log groups"
  type        = number
  default     = 14
}

variable "create_kms" {
  description = "Whether to create a KMS CMK for encryption of logs or other resources"
  type        = bool
  default     = false
}

variable "kms_alias" {
  description = "Alias to assign to the created KMS key when create_kms is true"
  type        = string
  default     = "alias/tt-practice-kms"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
