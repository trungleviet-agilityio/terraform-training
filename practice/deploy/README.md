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
- **S3 bucket for Terraform state backend**
- **DynamoDB table for Terraform state locking**
- **AWS Secrets Manager secrets** (create secrets)

**Deployment Order**: Must be deployed **first** before other layers.

**Note**: DynamoDB table in `10_core` is for Terraform state locking (infrastructure-for-Terraform), not application data. Application DynamoDB tables should be created in `20_infra` (shared) or `30_app` (app-specific).

### 20_infra - Platform Services Layer
**Purpose**: Platform services that applications depend on.

**Resources**:
- API Gateway HTTP API
- SQS queues (standard + DLQ)
- EventBridge schedules
- **Application DynamoDB tables** (if shared across applications)
- **Application S3 buckets** (if shared across applications)

**Dependencies**: Requires `10_core` outputs (tags, account ID, region).

### 30_app - Application Layer
**Purpose**: Application workloads and compute resources.

**Resources**:
- Lambda functions (FastAPI API, SQS worker, cron producer)
- Lambda Layers (for shared dependencies)
- Event source mappings and triggers
- Function-specific IAM roles
- **Application DynamoDB tables** (if app-specific)
- **Application S3 buckets** (if app-specific)

**Dependencies**: Requires `10_core` and `20_infra` outputs.

## Deployment Workflow

### Prerequisites

1. **AWS Credentials**: Configure AWS CLI with appropriate credentials
   ```bash
   aws configure
   ```

2. **Remote State**: S3 bucket and DynamoDB table will be created via Terraform modules in `10_core/modules/` (to be implemented)

3. **Backend Configuration**: Each environment has a `providers.tf` file with backend and provider configuration

### Deployment Steps

Deploy layers in sequential order: **10_core → 20_infra → 30_app**

#### Step 1: Deploy Core Layer

```bash
cd 10_core/environments/dev

# Initialize Terraform (backend config is in providers.tf)
terraform init

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
- Update state key in `providers.tf` backend configuration

#### Environment Variables

Each environment requires:
- `providers.tf`: Backend and provider configuration
- `terraform.tfvars`: Environment-specific variables (use `.example` as template)
- `variables.tf`: Variable definitions (shared across environments)
- `main.tf`: Module instantiation
- `outputs.tf`: Environment outputs

## Backend Configuration

Each layer maintains its own Terraform state file:

- **10_core**: `core/terraform.tfstate`
- **20_infra**: `infra/terraform.tfstate`
- **30_app**: `app/terraform.tfstate`

This separation allows:
- Independent deployment of each layer
- Layer-specific state management
- Easier debugging and rollback

## State Management

### Remote State Structure

```
s3://terraform-state-bucket/
├── core/terraform.tfstate
├── infra/terraform.tfstate
└── app/terraform.tfstate
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
│   ├── main.tf              # Resource definitions and module imports
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── locals.tf            # Local values
│   └── versions.tf          # Provider/terraform versions (optional)
├── environments/            # Environment-specific configs
│   └── <env>/
│       ├── providers.tf     # Backend and provider configuration
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

## Secret Management

Secrets follow a layered approach:

1. **10_core**: Creates Secrets Manager secrets
   - Define secrets with `aws_secretsmanager_secret`
   - Store secret values with `aws_secretsmanager_secret_version`
   - Output secret ARNs for use in other layers

2. **20_infra**: Grants access permissions
   - IAM policies grant `secretsmanager:GetSecretValue` permission
   - Attach policies to Lambda execution roles
   - Reference secret ARNs from `10_core` outputs

3. **30_app**: Consumes secrets at runtime
   - Lambda functions read secrets via AWS SDK
   - Or pass secret ARNs as environment variables
   - Never embed secret values directly

### Example Secret Creation (10_core)

```hcl
resource "aws_secretsmanager_secret" "api_key" {
  name        = "${var.project_name}-${var.environment}-api-key"
  description = "API key for external service"
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id
  secret_string = var.api_key_value  # Passed via CI/CD secrets
}
```

### Example Access Grant (20_infra)

```hcl
resource "aws_iam_role_policy" "lambda_secrets" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [module.core.api_key_secret_arn]
    }]
  })
}
```

### Example Secret Consumption (30_app)

```python
import boto3
import json

def lambda_handler(event, context):
    client = boto3.client('secretsmanager')
    secret_arn = os.environ['API_KEY_SECRET_ARN']
    
    response = client.get_secret_value(SecretId=secret_arn)
    api_key = json.loads(response['SecretString'])
    
    # Use api_key safely
    ...
```

**See**: `shared/docs/architecture.md` for detailed secret management strategy.

## Best Practices

1. **Always deploy in order**: Core → Infra → App
2. **Review plans before applying**: Use `terraform plan` before `terraform apply`
3. **Use version control**: Commit all `.tf` files, but **never commit**:
   - `terraform.tfstate` files
   - `terraform.tfvars` (use `.example` files)
   - `.terraform/` directories
4. **Environment isolation**: Keep environment-specific values in `terraform.tfvars`
5. **State management**: Never manually edit state files; use Terraform commands
6. **Secret management**: Use AWS Secrets Manager; never store secrets in code or variables (see Secret Management section below)

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
