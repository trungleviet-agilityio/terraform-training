locals {
  # Bucket name must be globally unique - use project name, environment, and unique suffix
  bucket_name = "${var.project_name}-tf-state-${var.environment}-${var.unique_suffix}"

  # DynamoDB table name for state locking
  dynamodb_table_name = "${var.project_name}-tf-locks"
}

# S3 bucket for Terraform state storage
resource "aws_s3_bucket" "state" {
  bucket = local.bucket_name

  tags = merge(
    var.tags,
    {
      Name        = local.bucket_name
      Purpose     = "Terraform State Storage"
      Environment = var.environment
    }
  )
}

# Enable versioning for state file history
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration for old state versions
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# DynamoDB table for Terraform state locking
# NOTE: This is infrastructure-for-Terraform (not application data)
resource "aws_dynamodb_table" "state_lock" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name        = local.dynamodb_table_name
      Purpose     = "Terraform State Locking"
      Environment = var.environment
    }
  )
}
