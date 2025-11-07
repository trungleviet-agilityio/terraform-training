variable "policy_name_prefix" {
  type        = string
  description = "Prefix for IAM policy names (e.g., 'github-actions-terraform'). Empty string to skip GitHub Actions policies."
  default     = ""

  validation {
    condition     = length(var.policy_name_prefix) >= 0
    error_message = "Policy name prefix must be a non-empty string or empty string."
  }
}

variable "state_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket used for Terraform state storage (required if creating GitHub Actions policies)."
  default     = ""

  validation {
    condition     = var.state_bucket_arn == "" || can(regex("^arn:aws:s3:::", var.state_bucket_arn))
    error_message = "State bucket ARN must be a valid S3 bucket ARN."
  }
}

variable "dynamodb_table_arn" {
  type        = string
  description = "ARN of the DynamoDB table used for Terraform state locking (required if creating GitHub Actions policies)."
  default     = ""

  validation {
    condition     = var.dynamodb_table_arn == "" || can(regex("^arn:aws:dynamodb:", var.dynamodb_table_arn))
    error_message = "DynamoDB table ARN must be a valid DynamoDB table ARN."
  }
}

variable "account_id" {
  type        = string
  description = "AWS account ID (required if creating GitHub Actions policies)."
  default     = ""

  validation {
    condition     = var.account_id == "" || can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}

variable "region" {
  type        = string
  description = "AWS region (required if creating GitHub Actions policies)."
  default     = ""

  validation {
    condition     = var.region == "" || length(var.region) > 0
    error_message = "Region must be a non-empty string."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all IAM policies."
  default     = {}
}

# Lambda Policy Variables (optional - only needed if creating Lambda policies)
variable "project_name" {
  type        = string
  description = "Project name for Lambda policy naming (required if creating Lambda policies)"
  default     = ""
}

variable "environment" {
  type        = string
  description = "Environment name for Lambda policy naming (required if creating Lambda policies)"
  default     = ""
}

variable "dynamodb_table_arns" {
  type        = list(string)
  description = "List of DynamoDB table ARNs (for Lambda DynamoDB permissions)"
  default     = []
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue (used in policy document, not for count)."
  default     = ""

  validation {
    condition     = var.sqs_queue_arn == "" || can(regex("^arn:aws:sqs:", var.sqs_queue_arn))
    error_message = "SQS queue ARN must be a valid SQS queue ARN."
  }
}

variable "enable_sqs_policy" {
  type        = bool
  description = "Whether to create the Lambda SQS access policy (SQS queue is always created, so this should be true)."
  default     = true
}
