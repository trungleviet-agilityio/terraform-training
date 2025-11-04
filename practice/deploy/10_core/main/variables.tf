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

variable "log_retention_in_days" {
  type        = number
  description = "Default log retention period in days for created log groups."
  default     = 14

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_in_days)
    error_message = "log_retention_in_days must be one of: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365, 400, 545, 731, 1827, 3653."
  }
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

  validation {
    condition     = can(regex("^alias/.*", var.kms_alias))
    error_message = "kms_alias must be a valid KMS alias starting with 'alias/'."
  }
}

variable "secrets" {
  type = map(object({
    description   = string
    secret_string = optional(string, null)
    kms_key_id    = optional(string, null)
  }))
  description = "Map of secrets to create in AWS Secrets Manager. Key is the secret name (without /practice/<environment>/ prefix)."
  default     = {}
  sensitive   = true
}
