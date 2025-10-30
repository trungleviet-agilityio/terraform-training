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

variable "log_retention_in_days" {
  type        = number
  description = "Default log retention period in days for created log groups."
  default     = 14
}

variable "create_kms" {
  type        = bool
  description = "Whether to create a KMS CMK for encryption of logs or other resources."
  default     = false
}

variable "kms_alias" {
  type        = string
  description = "Alias to assign to the created KMS key when create_kms is true."
  default     = "alias/tt-practice-kms"
}
