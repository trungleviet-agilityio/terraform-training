variable "policy_name_prefix" {
  type        = string
  description = "Prefix for IAM policy names (e.g., 'github-actions-terraform')."
  default     = "github-actions-terraform"

  validation {
    condition     = length(var.policy_name_prefix) > 0
    error_message = "Policy name prefix must be a non-empty string."
  }
}

variable "state_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket used for Terraform state storage."

  validation {
    condition     = can(regex("^arn:aws:s3:::", var.state_bucket_arn))
    error_message = "State bucket ARN must be a valid S3 bucket ARN."
  }
}

variable "dynamodb_table_arn" {
  type        = string
  description = "ARN of the DynamoDB table used for Terraform state locking."

  validation {
    condition     = can(regex("^arn:aws:dynamodb:", var.dynamodb_table_arn))
    error_message = "DynamoDB table ARN must be a valid DynamoDB table ARN."
  }
}

variable "account_id" {
  type        = string
  description = "AWS account ID."

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}

variable "region" {
  type        = string
  description = "AWS region."

  validation {
    condition     = length(var.region) > 0
    error_message = "Region must be a non-empty string."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all IAM policies."
  default     = {}
}
