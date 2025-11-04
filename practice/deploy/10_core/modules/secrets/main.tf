# Secret Module
# Creates AWS Secrets Manager secrets with standardized naming convention

resource "aws_secretsmanager_secret" "this" {
  name        = "/practice/${var.environment}/${var.secret_name}"
  description = var.description

  kms_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name = var.secret_name
    }
  )

  lifecycle {
    precondition {
      # Validate secret name format: must not contain slashes (environment is separate)
      condition     = !can(regex("/", var.secret_name))
      error_message = "Secret name must not contain forward slashes. The full path will be /practice/<environment>/<secret-name>."
    }
    precondition {
      # Validate secret name length (AWS Secrets Manager limit is 512 chars for full path)
      # We reserve space for /practice/<environment>/ prefix (typically ~20 chars)
      condition     = length(var.secret_name) > 0 && length(var.secret_name) <= 256
      error_message = "Secret name must be between 1 and 256 characters."
    }
    precondition {
      # Validate secret name contains only valid characters
      # AWS allows: alphanumeric, forward slash, hyphen, underscore, period, plus sign
      # But we exclude forward slash since it's used for path structure
      condition     = can(regex("^[a-zA-Z0-9_-]+$", var.secret_name))
      error_message = "Secret name can only contain alphanumeric characters, hyphens, and underscores."
    }
    precondition {
      # Validate environment is one of the allowed values
      condition     = contains(["dev", "stage", "prod"], var.environment)
      error_message = "Environment must be one of: dev, stage, prod."
    }
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  count         = var.secret_string != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
}
