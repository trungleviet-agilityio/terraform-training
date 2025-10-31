# Terraform State Backend Module

This module creates the S3 bucket and DynamoDB table for Terraform remote state management.

## Resources Created

- **S3 Bucket**: Stores Terraform state files
  - Versioning enabled
  - Server-side encryption (AES256)
  - Public access blocked
  - Lifecycle rule to expire old versions after 90 days

- **DynamoDB Table**: Provides state locking to prevent concurrent modifications
  - Pay-per-request billing mode
  - Hash key: `LockID` (string)
  - Server-side encryption enabled

## Usage

```hcl
module "state_backend" {
  source = "../modules/s3"

  project_name  = "tt-practice"
  environment   = "dev"
  unique_suffix = "123456789012"  # Account ID or other unique identifier

  tags = {
    Environment = "dev"
    Project     = "tt-practice"
    ManagedBy   = "Terraform"
  }
}
```

## Outputs

- `bucket_name`: Name of the S3 bucket
- `bucket_arn`: ARN of the S3 bucket
- `dynamodb_table_name`: Name of the DynamoDB table
- `dynamodb_table_arn`: ARN of the DynamoDB table

## Naming Convention

- Bucket: `{project_name}-tf-state-{environment}-{unique_suffix}`
- DynamoDB Table: `{project_name}-tf-locks`

## Security

- S3 bucket has all public access blocked
- State files are encrypted at rest
- DynamoDB table has encryption enabled
- IAM policies should be configured separately to restrict access

