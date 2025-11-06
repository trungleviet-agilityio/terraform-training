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
│   └── main.tf           # Imports state backend module
├── modules/
│   └── state-backend/    # Module for S3 bucket + DynamoDB table
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

### Backend Configuration

Each environment uses a two-file approach for backend configuration:

1. **`providers.tf`**: Contains static backend configuration (region, key, encrypt, dynamodb_table)
2. **`backend.tfvars`**: Contains environment-specific values (bucket name)

#### Example: `deploy/30_app/environments/dev/providers.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend configuration
  # Environment-specific values (bucket name) are provided via backend.tfvars
  # Usage: terraform init -backend-config=backend.tfvars
  backend "s3" {
    key            = "app/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "tt-practice-tf-locks"
    # bucket is provided via backend.tfvars file
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

#### Example: `deploy/30_app/environments/dev/backend.tfvars`

```hcl
# Backend Configuration for Development Environment
# Usage: terraform init -backend-config=backend.tfvars
#
# This file contains environment-specific backend configuration
# The bucket name should follow the pattern: tt-practice-tf-state-{environment}-{account-id}
# Replace <account-id> with your AWS account ID after first deployment

bucket = "tt-practice-tf-state-dev-057336397237"
```

**Important**: 
- The bucket name is environment-specific and provided via `backend.tfvars`
- State key uses pattern: `<layer>/terraform.tfstate` (e.g., `core/terraform.tfstate`, `infra/terraform.tfstate`, `app/terraform.tfstate`)
- Initialize with: `terraform init -backend-config=backend.tfvars`
- Other backend config (key, region, encrypt, dynamodb_table) is in `providers.tf`

## Bootstrap Process (First Deployment)

**⚠️ CRITICAL**: The `10_core` layer has a chicken-and-egg problem: it creates the state backend (S3 bucket and DynamoDB table), but Terraform needs the backend to exist before it can use it.

### Step 1: Bootstrap 10_core Layer (First Time Only)

For the **first deployment** of `10_core`, you must bootstrap with local state:

**⚠️ IMPORTANT**: Do NOT comment out the backend block inside `providers.tf` - this causes Terraform parsing errors. Use one of these methods:

**Method 1: Rename File (Recommended)**:

```bash
cd deploy/10_core/environments/dev

# Step 1: Backup the providers.tf with backend config
cp providers.tf providers.tf.backend

# Step 2: Create temporary providers.tf without backend (copy from providers.tf.local.example or create manually)
# The temporary file should have NO backend block, only terraform { required_version, required_providers } and provider config

# Step 3: Initialize with local state (no backend)
terraform init

# Step 4: Apply to create state backend resources
terraform apply -var-file=terraform.tfvars

# Step 5: Get bucket name from outputs
terraform output state_backend_bucket_name

# Step 6: Update backend.tfvars with the actual bucket name
# Edit backend.tfvars and update the bucket value

# Step 7: Restore providers.tf with backend config
cp providers.tf.backend providers.tf

# Step 8: Reinitialize with backend and migrate state
terraform init -backend-config=backend.tfvars -migrate-state

# Step 9: Verify migration
terraform state list

# Step 10: Clean up backup file
rm providers.tf.backend
```

**Method 2: Use providers.tf.local.example**:

A helper file `providers.tf.local.example` is provided. Copy it:

```bash
cd deploy/10_core/environments/dev

# Backup original
cp providers.tf providers.tf.backend

# Use local state version
cp providers.tf.local.example providers.tf

# Continue with steps 3-9 from Method 1 above
```

**What this does:**
1. Creates the S3 bucket and DynamoDB table using local state
2. Migrates the local state to the newly created S3 backend
3. Future operations will use the remote backend

**Why not comment out?**: Commenting out the backend block inside the `terraform {}` block can cause Terraform parser errors because it expects valid HCL syntax. Renaming/swapping files is cleaner and avoids syntax issues.

### Step 2: Deploy Other Layers (After Bootstrap)

After `10_core` is bootstrapped, other layers (`20_infra`, `30_app`) can be initialized normally:

```bash
cd deploy/20_infra/environments/dev
terraform init -backend-config=backend.tfvars
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

**Note**: Other layers don't need bootstrap because they reference the state backend created by `10_core`.

## Remote State Usage Across Layers

This project uses **Terraform Remote State** (`terraform_remote_state` data source) to share outputs between layers automatically.

### How Remote State Works

Instead of manually copying ARNs or IDs between layers, we use `terraform_remote_state` to automatically retrieve outputs from other layers' state files.

**Layer Dependencies**:
```
10_core (Foundation)
    ↓ outputs: state_backend_bucket_arn, state_backend_dynamodb_table_arn, account_id
20_infra (Platform Services)
    ↓ outputs: sqs_queue_arn
30_app (Application)
```

### Example: 20_infra Gets Backend Config from 10_core

**File**: `deploy/20_infra/environments/dev/main.tf`

```hcl
# Get AWS account ID for constructing bucket name
data "aws_caller_identity" "current" {}

# Get remote state from 10_core layer
data "terraform_remote_state" "core" {
  backend = "s3"

  config = {
    bucket  = "tt-practice-tf-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key     = "core/terraform.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

# Use outputs from 10_core
module "main" {
  source = "../../main"

  backend_config = {
    bucket_arn = data.terraform_remote_state.core.outputs.state_backend_bucket_arn
    table_arn  = data.terraform_remote_state.core.outputs.state_backend_dynamodb_table_arn
    account_id = data.terraform_remote_state.core.outputs.account_id
  }
}
```

**Benefits**:
- No manual configuration needed in `terraform.tfvars`
- Automatically uses same bucket name pattern
- Type-safe (Terraform validates outputs exist)

### Example: 30_app Gets SQS Queue ARN from 20_infra

**File**: `deploy/30_app/environments/dev/main.tf`

```hcl
# Get remote state from 20_infra layer
data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket  = "tt-practice-tf-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key     = "infra/terraform.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

# Use outputs from 20_infra
module "main" {
  source = "../../main"

  sqs_queue_arn = try(data.terraform_remote_state.infra.outputs.sqs_queue_arn, "")
}
```

### Bucket Name Pattern

All layers use the same bucket name pattern:
```
tt-practice-tf-state-${environment}-${account_id}
```

This is constructed using:
- `var.environment` (dev, stage, prod)
- `data.aws_caller_identity.current.account_id` (AWS account ID)

**Why this pattern?**
- Consistent across all layers
- Environment-specific buckets
- No hardcoding needed

### Deployment Order

**Always deploy in this order:**

1. **10_core** → Creates state backend (S3 bucket + DynamoDB table)
2. **20_infra** → Gets backend config from 10_core via remote state, creates platform services
3. **30_app** → Gets SQS queue ARN from 20_infra via remote state, creates Lambda functions

**See**: `shared/docs/terraform-state-and-backend.md` for comprehensive guide on Terraform state, backend, and remote state usage.

### Alternative: Manual Bootstrap (If Needed)

If you prefer to create the state backend resources manually:

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket tt-practice-tf-state-dev-<account-id> \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket tt-practice-tf-state-dev-<account-id> \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket tt-practice-tf-state-dev-<account-id> \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket tt-practice-tf-state-dev-<account-id> \
  --public-access-block-configuration \
    "BlockPublicAcls=true,BlockPublicPolicy=true,IgnorePublicAcls=true,RestrictPublicBuckets=true"

# Create DynamoDB table
aws dynamodb create-table \
  --table-name tt-practice-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

Then initialize `10_core` normally with `terraform init -backend-config=backend.tfvars`.

## Initialization

After the state backend module is implemented and deployed, initialize Terraform:

```bash
cd deploy/30_app/environments/dev
terraform init -backend-config=backend.tfvars
```

**Initialization Steps**:

1. **Update backend.tfvars**: Set the bucket name with your AWS account ID
   ```bash
   # Edit backend.tfvars
   bucket = "tt-practice-tf-state-dev-<your-account-id>"
   ```

2. **Initialize Terraform**: Use the `-backend-config` flag to load backend configuration
   ```bash
   terraform init -backend-config=backend.tfvars
   ```

3. **Verify**: Check that backend is configured correctly
   ```bash
   terraform state list
   ```

**Note**: Each environment (dev, stage, prod) has its own `backend.tfvars` file with environment-specific bucket names. This allows using different state buckets per environment while keeping shared configuration in `providers.tf`.

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
terraform init -backend-config=backend.tfvars -migrate-state
```

To migrate between backends:

```bash
# Update backend.tfvars with new backend configuration
terraform init -backend-config=backend.tfvars -migrate-state
```

To reconfigure backend:

```bash
# Update backend.tfvars with new values
terraform init -backend-config=backend.tfvars -reconfigure
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
- `shared/docs/terraform-state-and-backend.md` - Comprehensive guide on Terraform state, backend, and workflow
- `deploy/README.md` - Deployment workflows
- `shared/docs/ci-cd.md` - CI/CD configuration
