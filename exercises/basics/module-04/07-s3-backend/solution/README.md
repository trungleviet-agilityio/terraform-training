# S3 Backend Configuration

This solution demonstrates how to configure Terraform with an S3 backend for remote state storage and DynamoDB for state locking.

## Features

- **Remote State Storage**: Terraform state is stored in S3
- **State Locking**: DynamoDB table prevents concurrent state modifications
- **Environment Separation**: Different backend configurations for dev/prod
- **Encryption**: State files are encrypted at rest
- **Version Control**: State locking prevents corruption

## Files Overview

- `providers.tf` - Main Terraform configuration with S3 backend
- `dynamodb.tf` - DynamoDB table for state locking
- `variables.tf` - Configuration variables
- `dev.s3.tfbackend` - Development environment backend config
- `prod.s3.tfbackend` - Production environment backend config

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. S3 bucket created manually (or use the bucket name in the config)
3. Terraform version 1.6 or later

## ⚠️ Important: S3 Bucket Name Uniqueness

**S3 bucket names must be globally unique across ALL AWS accounts worldwide.** If you encounter a "bucket already exists" error:

1. **Change the bucket name** in `providers.tf` to something unique
2. **Use your name, company, or random string** as a prefix
3. **Examples of unique names**:
   - `terraform-backend-trungle-2024`
   - `my-company-terraform-state-bucket`
   - `terraform-backend-abc123xyz`

## Usage

### Initial Setup

1. **Create the DynamoDB table first** (if not using existing):
   ```bash
   terraform init
   terraform apply -target=aws_dynamodb_table.terraform_state_lock
   ```

2. **Initialize with S3 backend**:
   ```bash
   terraform init
   ```

### Environment-Specific Backends

**For Development:**
```bash
terraform init -backend-config=dev.s3.tfbackend
```

**For Production:**
```bash
terraform init -backend-config=prod.s3.tfbackend
```

### Apply Configuration

```bash
terraform plan
terraform apply
```

## Backend Configuration Details

The S3 backend is configured with:
- **Bucket**: `my-terraform-remote-backend-bucket-trungle`
- **Key**: Environment-specific paths (`environments/dev/` or `environments/prod/`)
- **Region**: `us-east-1`
- **Encryption**: Enabled
- **State Locking**: DynamoDB table `terraform-state-lock`

## Security Considerations

- State files are encrypted at rest
- DynamoDB table uses pay-per-request billing
- Environment-specific state isolation
- Proper IAM permissions required for S3 and DynamoDB access

## Troubleshooting

### Region Mismatch Error
If you get an error like "requested bucket from 'eu-west-1', actual location 'us-east-1'":

1. **Check your bucket's actual region**:
   ```bash
   aws s3api get-bucket-location --bucket your-bucket-name
   ```

2. **Update the region** in your backend configuration to match the bucket's actual region

3. **Re-initialize Terraform**:
   ```bash
   terraform init -reconfigure
   ```

### Common Issues
- **Bucket doesn't exist**: Create the S3 bucket manually first
- **Permission denied**: Ensure your AWS credentials have S3 and DynamoDB permissions
- **DynamoDB table doesn't exist**: Create the table first or let Terraform create it

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Note**: The S3 bucket and DynamoDB table will be destroyed. Make sure to backup any important state files before running destroy.
