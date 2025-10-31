# Terraform Deployment Guide

This directory contains all Terraform infrastructure code organized into three layers with multi-environment support.

## Directory Structure

```
deploy/
├── 10_core/           # Foundation layer (must be deployed first)
│   ├── main/          # Core module implementation
│   ├── environments/  # Environment-specific configurations
│   └── modules/       # Reusable sub-modules
├── 20_infra/          # Platform services layer
├── 30_app/            # Application workloads layer
├── components/        # Shared reusable components
└── scripts/           # Deployment helper scripts
```

## Layer Overview

### 10_core - Foundation Layer
**Purpose**: Base infrastructure resources shared across all environments.

**Resources**:
- Standard tags and naming conventions
- Optional KMS CMK for encryption
- Base IAM roles and policies
- CloudWatch log retention settings
- AWS account/region data sources

**Deployment Order**: Must be deployed **first** before other layers.

### 20_infra - Platform Services Layer
**Purpose**: Platform services that applications depend on.

**Resources**:
- API Gateway HTTP API
- SQS queues (standard + DLQ)
- EventBridge schedules

**Dependencies**: Requires `10_core` outputs (tags, account ID, region).

### 30_app - Application Layer
**Purpose**: Application workloads and compute resources.

**Resources**:
- Lambda functions (FastAPI API, SQS worker, cron producer)
- Lambda Layers (for shared dependencies)
- Event source mappings and triggers
- Function-specific IAM roles

**Dependencies**: Requires `10_core` and `20_infra` outputs.

## Deployment Workflow

### Prerequisites

1. **AWS Credentials**: Configure AWS CLI with appropriate credentials
   ```bash
   aws configure
   ```

2. **Remote State**: Bootstrap S3 bucket and DynamoDB table for Terraform state
   ```bash
   # Script to be created
   ./scripts/bootstrap_state.sh \
     --bucket tt-practice-tf-state-<unique> \
     --table tt-practice-tf-locks \
     --region us-east-1
   ```

3. **Backend Configuration**: Create `backend.tfvars` files for each environment
   ```hcl
   bucket         = "tt-practice-tf-state-<unique>"
   dynamodb_table = "tt-practice-tf-locks"
   key            = "10_core/dev/terraform.tfstate"
   region         = "us-east-1"
   encrypt        = true
   ```

### Deployment Steps

Deploy layers in sequential order: **10_core → 20_infra → 30_app**

#### Step 1: Deploy Core Layer

```bash
cd 10_core/environments/dev

# Initialize Terraform with backend configuration
terraform init -backend-config=backend.tfvars

# Review the plan
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

#### Step 2: Deploy Infrastructure Layer

```bash
cd ../../20_infra/environments/dev

# Initialize Terraform
terraform init -backend-config=backend.tfvars

# Review the plan
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

#### Step 3: Deploy Application Layer

```bash
cd ../../30_app/environments/dev

# Initialize Terraform
terraform init -backend-config=backend.tfvars

# Review the plan
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

### Environment Management

#### Create New Environment

Use the helper script to scaffold a new environment for any layer:

```bash
./scripts/create_environment.sh <layer> <environment>
# Example:
./scripts/create_environment.sh 20_infra staging
```

This will:
- Copy `dev` environment configuration as a template
- Update environment name in `terraform.tfvars`
- Update backend state key in `backend.tfvars`

#### Environment Variables

Each environment requires:
- `terraform.tfvars`: Environment-specific variables
- `backend.tfvars`: Backend configuration (S3 bucket, DynamoDB table)
- `variables.tf`: Variable definitions (shared across environments)

## Backend Configuration

Each layer maintains its own Terraform state file:

- **10_core**: `10_core/<env>/terraform.tfstate`
- **20_infra**: `20_infra/<env>/terraform.tfstate`
- **30_app**: `30_app/<env>/terraform.tfstate`

This separation allows:
- Independent deployment of each layer
- Layer-specific state management
- Easier debugging and rollback

## State Management

### Remote State Structure

```
s3://terraform-state-bucket/
├── 10_core/
│   ├── dev/terraform.tfstate
│   ├── stage/terraform.tfstate
│   └── prod/terraform.tfstate
├── 20_infra/
│   ├── dev/terraform.tfstate
│   ├── stage/terraform.tfstate
│   └── prod/terraform.tfstate
└── 30_app/
    ├── dev/terraform.tfstate
    ├── stage/terraform.tfstate
    └── prod/terraform.tfstate
```

### State Locking

DynamoDB table provides state locking to prevent concurrent modifications:
- Table: `tt-practice-tf-locks`
- Primary key: `LockID` (string)
- Billing mode: Pay-per-request

## Module Structure

Each layer follows this structure:

```
<layer>/
├── main/                    # Main module implementation
│   ├── main.tf              # Resource definitions
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── locals.tf            # Local values
│   └── versions.tf          # Provider/terraform versions
├── environments/            # Environment-specific configs
│   └── <env>/
│       ├── backend.tf       # Backend configuration
│       ├── providers.tf      # Provider configuration
│       ├── main.tf           # Module instantiation
│       ├── variables.tf     # Variable definitions
│       ├── outputs.tf        # Environment outputs
│       └── terraform.tfvars.example  # Example variables
└── modules/                 # Reusable sub-modules
```

## Helper Scripts

### `scripts/create_environment.sh`

Creates a new environment configuration by copying from `dev`:

```bash
./scripts/create_environment.sh <layer> <environment>
```

**Example**:
```bash
./scripts/create_environment.sh 30_app staging
```

### `scripts/bootstrap_state.sh` (to be created)

Initializes remote state backend (S3 + DynamoDB).

## Best Practices

1. **Always deploy in order**: Core → Infra → App
2. **Review plans before applying**: Use `terraform plan` before `terraform apply`
3. **Use version control**: Commit all `.tf` files, but **never commit**:
   - `terraform.tfstate` files
   - `terraform.tfvars` (use `.example` files)
   - `.terraform/` directories
4. **Environment isolation**: Keep environment-specific values in `terraform.tfvars`
5. **State management**: Never manually edit state files; use Terraform commands

## Troubleshooting

### State Lock Issues

If state is locked:
```bash
# Check DynamoDB table for lock entries
aws dynamodb scan --table-name tt-practice-tf-locks

# In emergency, manually delete lock (use with caution)
aws dynamodb delete-item \
  --table-name tt-practice-tf-locks \
  --key '{"LockID": {"S": "your-lock-id"}}'
```

### Backend Migration

To migrate from local to remote state:
```bash
terraform init -migrate-state
```

### Import Existing Resources

To import existing AWS resources:
```bash
terraform import <resource_type>.<resource_name> <resource_id>
```
