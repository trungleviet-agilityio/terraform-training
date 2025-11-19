variable "secret_name" {
  type        = string
  description = "Name of the secret (without the /practice/<environment>/<layer>/ prefix)."

  validation {
    condition     = length(var.secret_name) > 0
    error_message = "secret_name must be a non-empty string."
  }
}

variable "layer" {
  type        = string
  description = "Layer name (10_core, 20_infra, 30_app). Optional - if not provided, secret is created at environment level."
  default     = null

  validation {
    condition     = var.layer == null ? true : contains(["10_core", "20_infra", "30_app"], var.layer)
    error_message = "Layer must be one of: 10_core, 20_infra, 30_app, or null."
  }
}

variable "description" {
  type        = string
  description = "Description of the secret."

  validation {
    condition     = length(var.description) > 0
    error_message = "description must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, stage, prod)."

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "secret_string" {
  type        = string
  description = "Secret value as a string. Optional - can be set later via AWS Console or CI/CD. If null, secret will be created without a value."
  default     = null
  sensitive   = true
}

variable "kms_key_id" {
  type        = string
  description = "ARN or ID of the AWS KMS key to encrypt the secret. If not provided, AWS Secrets Manager uses the default KMS key."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to the secret."
  default     = {}
}
