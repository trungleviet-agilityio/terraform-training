# Terraform Remote State Configuration

This guide explains how remote state backend will be configured for Terraform infrastructure management.

## Overview

Terraform remote state stores infrastructure state in an S3 bucket with DynamoDB providing state locking to prevent concurrent modifications.

**Implementation Approach**: S3 bucket and DynamoDB table will be created via Terraform modules in `10_core/modules/` and imported into `10_core/main/`, following the same pattern as other modules (secrets, core, dns, etc.).

## Module Structure (Future Implementation)

The remote state backend will be created using Terraform modules:

```
10_core/
├── main/
│   └── main.tf          # Imports state backend module
├── modules/
│   └── state-backend/   # Module for S3 bucket + DynamoDB table
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    └── dev/
        └── providers.tf  # Backend and provider configuration
```

## Backend Configuration

Each layer has its own state file in the S3 bucket:

### State Key Structure

Each layer uses a simple state key pattern:

- `core/terraform.tfstate` (for 10_core layer)
- `infra/terraform.tfstate` (for 20_infra layer)
- `app/terraform.tfstate` (for 30_app layer)

Each environment has its own backend configuration in `providers.tf` with the appropriate state key.

### Backend Configuration File

Each environment has a `providers.tf` file that contains both backend and provider configuration:

#### Example: `deploy/10_core/environments/dev/providers.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tt-practice-tf-state-<unique>"
    key            = "core/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "tt-practice-tf-locks"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
```

**Important**: 
- Update the `bucket` name with your unique identifier
- State key uses pattern: `<layer>/terraform.tfstate` (e.g., `core/terraform.tfstate`, `infra/terraform.tfstate`, `app/terraform.tfstate`)
- Backend configuration is in the same file as provider configuration (`providers.tf`)

## Initialization

After the state backend module is implemented and deployed, initialize Terraform:

```bash
cd deploy/10_core/environments/dev
terraform init
```

**Note**: Backend configuration is now directly in `providers.tf`, so no `-backend-config` flag is needed.

## State File Structure

```
s3://tt-practice-tf-state-<unique>/
├── core/terraform.tfstate
├── infra/terraform.tfstate
└── app/terraform.tfstate
```

## Security Best Practices

### S3 Bucket Security

The state backend module will configure:
- **Versioning**: Enables version history for state files
- **Encryption**: SSE-S3 encryption at rest
- **Public Access**: Blocked by default
- **Access Control**: IAM policies restrict access

### DynamoDB Table Security

- **IAM Policies**: Restrict access to specific roles/users
- **Encryption**: DynamoDB encryption at rest (default in most regions)
- **Billing**: Pay-per-request mode (no minimum charges)

### IAM Policies for CI/CD

GitHub Actions or other CI/CD systems need:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::tt-practice-tf-state-<unique>",
        "arn:aws:s3:::tt-practice-tf-state-<unique>/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:<region>:<account>:table/tt-practice-tf-locks"
    }
  ]
}
```

## Troubleshooting

### State Lock Issues

If Terraform operations are blocked by a lock:

```bash
# Check for active locks
aws dynamodb scan --table-name tt-practice-tf-locks

# In emergency, manually delete lock (use with caution)
aws dynamodb delete-item \
  --table-name tt-practice-tf-locks \
  --key '{"LockID": {"S": "your-lock-id"}}'
```

**Warning**: Only delete locks if you're certain no other Terraform process is running.

### Backend Migration

To migrate from local to remote state:

```bash
terraform init -migrate-state
```

To migrate between backends:

```bash
# Update backend.tfvars with new backend
terraform init -migrate-state
```

### Verifying Backend Configuration

```bash
# Check current backend configuration
terraform init

# Verify state location
terraform state list
```

## Cost Considerations

### S3 Costs
- Storage: ~$0.023 per GB/month
- PUT requests: ~$0.005 per 1,000 requests
- GET requests: ~$0.0004 per 1,000 requests

### DynamoDB Costs (Pay-per-request)
- Reads: ~$0.25 per million requests
- Writes: ~$1.25 per million requests

**Estimated monthly cost**: < $1 for small teams with moderate usage

## Implementation Status

**Current Status**: Not yet implemented

The state backend module will be created in a future implementation phase following the established module pattern in `10_core/modules/`.

## Next Steps

After state backend module is implemented:

1. Deploy state backend module via `10_core/main/`
2. Update `providers.tf` in each environment with correct bucket name
3. Initialize Terraform backends
4. Configure CI/CD secrets with backend configuration
5. Begin deploying infrastructure layers

See also:
- `deploy/README.md` for deployment workflows
- `shared/docs/ci-cd.md` for CI/CD configuration

