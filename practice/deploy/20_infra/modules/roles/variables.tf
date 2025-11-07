variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the OIDC provider for GitHub Actions (required if creating GitHub Actions roles)."
  default     = ""

  validation {
    condition     = var.oidc_provider_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/", var.oidc_provider_arn))
    error_message = "OIDC provider ARN must be a valid IAM OIDC provider ARN."
  }
}

variable "github_organization" {
  type        = string
  description = "GitHub organization name (required if creating GitHub Actions roles)."
  default     = ""

  validation {
    condition     = var.github_organization == "" || length(var.github_organization) > 0
    error_message = "GitHub organization must be a non-empty string."
  }
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name (required if creating GitHub Actions roles)."
  default     = ""

  validation {
    condition     = var.github_repository == "" || length(var.github_repository) > 0
    error_message = "GitHub repository must be a non-empty string."
  }
}

variable "create_terraform_plan_role" {
  type        = bool
  description = "Whether to create the Terraform plan role."
  default     = false
}

variable "create_terraform_apply_role" {
  type        = bool
  description = "Whether to create the Terraform apply role."
  default     = false
}

variable "terraform_plan_role_name" {
  type        = string
  description = "Name of the Terraform plan IAM role."
  default     = "github-actions-terraform-plan"

  validation {
    condition     = length(var.terraform_plan_role_name) > 0
    error_message = "Terraform plan role name must be a non-empty string."
  }
}

variable "terraform_apply_role_name" {
  type        = string
  description = "Name of the Terraform apply IAM role."
  default     = "github-actions-terraform-apply"

  validation {
    condition     = length(var.terraform_apply_role_name) > 0
    error_message = "Terraform apply role name must be a non-empty string."
  }
}

variable "terraform_plan_policy_arn" {
  type        = string
  description = "ARN of the IAM policy for Terraform plan operations (required if creating plan role)."
  default     = ""

  validation {
    condition     = var.terraform_plan_policy_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:policy/", var.terraform_plan_policy_arn))
    error_message = "Terraform plan policy ARN must be a valid IAM policy ARN."
  }
}

variable "terraform_apply_policy_arn" {
  type        = string
  description = "ARN of the IAM policy for Terraform apply operations (required if creating apply role)."
  default     = ""

  validation {
    condition     = var.terraform_apply_policy_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:policy/", var.terraform_apply_policy_arn))
    error_message = "Terraform apply policy ARN must be a valid IAM policy ARN."
  }
}

variable "allowed_branches" {
  type        = list(string)
  description = "Optional list of allowed branches for role assumption (e.g., ['main', 'develop']). If null or empty, all branches are allowed."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all IAM roles."
  default     = {}
}

# Lambda Role Variables (optional - only needed if creating Lambda roles)
variable "create_lambda_roles" {
  type        = bool
  description = "Whether to create Lambda execution roles"
  default     = false
}

variable "project_name" {
  type        = string
  description = "Project name for Lambda role naming (required if create_lambda_roles is true)"
  default     = ""
}

variable "environment" {
  type        = string
  description = "Environment name for Lambda role naming (required if create_lambda_roles is true)"
  default     = ""
}

variable "lambda_policies" {
  type = object({
    lambda_dynamodb_access_policy_arn = optional(string)
    lambda_sqs_access_policy_arn      = optional(string)
  })
  description = "IAM policies for Lambda roles (from policies module)"
  default = {
    lambda_dynamodb_access_policy_arn = null
    lambda_sqs_access_policy_arn      = null
  }
}

variable "enable_dynamodb_policy" {
  type        = bool
  description = "Whether to attach DynamoDB access policy to Lambda roles (based on whether DynamoDB tables exist)"
  default     = false
}

variable "enable_sqs_policy" {
  type        = bool
  description = "Whether to attach SQS access policy to Lambda roles (based on whether SQS queue exists)"
  default     = false
}
