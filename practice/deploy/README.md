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

#### Lambda Module Architecture

The application layer uses a modular component-based architecture:

**Components** (`deploy/components/`):
- `lambda_simple_package`: Packages Lambda source code into zip files
- `lambda_fastapi_server`: FastAPI Lambda wrapper component
- `lambda_cron_server`: Cron Lambda wrapper component
- `lambda_sqs_worker`: SQS worker Lambda wrapper component

**Modules** (`deploy/30_app/modules/`):
- `runtime_code_modules`: Packages all Lambda source code
- `lambda_roles`: Creates IAM execution roles for Lambda functions
- `api_server`: API Lambda module
- `cron_server`: Cron Lambda module
- `worker`: Worker Lambda module

**Lambda Functions**:
1. **API Server**: FastAPI application for HTTP API requests (triggered by API Gateway)
2. **Cron Server**: Scheduled tasks via EventBridge (triggered by cron schedule)
3. **Worker**: Processes messages from SQS queue (triggered by SQS event source mapping)

See individual module README files for detailed usage and examples.

## Deployment Workflow

### Prerequisites

1. **AWS Credentials**: Configure AWS CLI with appropriate credentials
   ```bash
   aws configure
   ```

2. **Remote State**: S3 bucket and DynamoDB table will be created via Terraform modules in `10_core/modules/` (to be implemented)

3. **Backend Configuration**: 
   - Each environment has a `providers.tf` file with static backend configuration
   - Each environment has a `backend.tfvars` file with environment-specific bucket name
   - Initialize with: `terraform init -backend-config=backend.tfvars`

### Deployment Steps

Deploy layers in sequential order: **10_core → 20_infra → 30_app**

#### Step 1: Deploy Core Layer

**⚠️ IMPORTANT**: For **first deployment**, you must bootstrap with local state. See `shared/docs/remote-state.md` for detailed bootstrap instructions.

**Bootstrap Process (First Time Only)**:

**⚠️ Do NOT comment out the backend block** - this causes Terraform parsing errors. Use file swapping instead:

```bash
cd 10_core/environments/dev

# Step 1: Backup providers.tf with backend config
cp providers.tf providers.tf.backend

# Step 2: Use local state version (no backend block)
cp providers.tf.local.example providers.tf

# Step 3: Initialize with local state
terraform init

# Step 4: Apply to create state backend resources
terraform apply -var-file=terraform.tfvars

# Step 5: Get bucket name from outputs
terraform output state_backend_bucket_name

# Step 6: Update backend.tfvars with bucket name
# (Edit backend.tfvars and update bucket value)

# Step 7: Restore providers.tf with backend config
cp providers.tf.backend providers.tf

# Step 8: Reinitialize and migrate state
terraform init -backend-config=backend.tfvars -migrate-state

# Step 9: Clean up backup
rm providers.tf.backend
```

**Normal Deployment (After Bootstrap)**:

```bash
cd 10_core/environments/dev

# Initialize Terraform
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

**Remote State Usage**: Layers use `terraform_remote_state` to share outputs automatically:
- **20_infra** gets backend configuration from **10_core** (no manual `backend_config` needed)
- **30_app** gets SQS queue ARN from **20_infra** (no manual configuration needed)

See `shared/docs/terraform-state-and-backend.md` for detailed information about remote state usage.

### Backend Configuration Pattern

Backend configuration uses a two-file approach:

1. **`providers.tf`**: Contains static backend configuration (region, key, encrypt, dynamodb_table)
2. **`backend.tfvars`**: Contains environment-specific values (bucket name)

**Initialization**:
```bash
cd deploy/30_app/environments/dev
terraform init -backend-config=backend.tfvars
```

**Why this pattern?**
- Avoids hardcoded bucket names in version control
- Allows different buckets per environment
- Keeps shared configuration in `providers.tf`
- Environment-specific values in `backend.tfvars` (can be gitignored if needed)

**Best Practices**:
- Update `backend.tfvars` with your AWS account ID
- Use consistent bucket naming: `tt-practice-tf-state-{environment}-{account-id}`
- Keep `backend.tfvars` in version control (bucket names are not sensitive)
- Each environment folder has its own `backend.tfvars` file

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

## Output Management

### Output Structure

This project uses a three-level output structure to support `terraform_remote_state`:

```
modules/*/outputs.tf     → Module-level outputs
main/outputs.tf          → Re-exposes module outputs
environments/dev/outputs.tf → Re-exposes main outputs (for remote state access)
```

**Why this duplication?**

The `terraform_remote_state` data source can only access outputs from the **root module** (the directory where `terraform apply` runs). Since we run from `environments/dev/`, outputs must be re-exposed there.

### Best Practices

1. **Only expose outputs in `environments/dev/outputs.tf` that are:**
   - Consumed via `terraform_remote_state` by other layers, OR
   - Useful for debugging/troubleshooting (via `terraform output`)

2. **Always reference main outputs**: `value = module.main.output_name`

3. **Document the purpose**: Add comments indicating which outputs are for remote state vs general use

4. **Validate consistency**: Use the validation script to ensure outputs stay in sync

### Validating Outputs

Use the validation script to check output consistency:

```bash
# Validate all layers
./deploy/scripts/validate-outputs.sh

# Validate specific layer
./deploy/scripts/validate-outputs.sh 10_core
```

The script ensures:
- ✅ Environment outputs reference `module.main.*`
- ✅ Referenced main outputs exist
- ✅ Outputs are properly mapped

**See**: 
- `shared/docs/terraform-state-and-backend.md` - Detailed explanation of output structure
- `shared/docs/output-reference.md` - Complete output reference table

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

## Variable Management

### Variable Flow Pattern

Variables flow from environment root modules → main modules → sub-modules:

```
terraform.tfvars (environment-specific values)
    ↓
environments/<env>/variables.tf (root module declares variables)
    ↓
environments/<env>/main.tf (passes variables to main module)
    ↓
main/variables.tf (module declares minimal input variables)
    ↓
main/main.tf (uses variables, passes to sub-modules)
    ↓
modules/*/variables.tf (sub-modules define their own defaults)
```

### Design Principle: Minimal Variable Declaration

**Main modules only declare variables that:**
1. Are passed to multiple sub-modules (e.g., `project_name`, `environment`)
2. Are required by sub-modules (no default in sub-module)
3. Truly vary per environment AND need to be configurable

**Main modules DON'T declare variables when:**
- Sub-module already has a good default value
- Value is only used in one place and doesn't vary
- Configuration is practice-specific and shouldn't change

**Example:**
```hcl
# main/variables.tf - Only essential variables
variable "project_name" { ... }  # Used by multiple modules
variable "environment" { ... }   # Used by multiple modules

# Don't declare these - let sub-modules use their defaults
# variable "log_retention_in_days" { default = 14 }  # Module has default
# variable "sqs_queue_name" { default = "main" }     # Module has default
```

```hcl
# main/main.tf - Only pass required parameters
module "log_retention" {
  source = "../modules/log-retention"
  # Don't pass log_retention_in_days - module uses default (14 days)
  tags = local.common_tags
}

module "sqs" {
  source = "../modules/sqs"
  project_name = var.project_name  # Required (no default in module)
  environment  = var.environment   # Required (no default in module)
  # Don't pass queue_name or enable_dlq - module uses defaults
  tags = local.common_tags
}
```

### Variable Grouping Strategy

To reduce duplication, related variables are grouped into object types:

**Example: GitHub OIDC Configuration**
```hcl
# Instead of 7 separate variables:
variable "github_organization" { ... }
variable "github_repository" { ... }
variable "create_oidc_provider" { ... }
# ... etc

# We use a single grouped variable:
variable "github_oidc_config" {
  type = object({
    organization      = string
    repository        = string
    create_oidc       = bool
    create_policies   = bool
    create_plan_role  = bool
    create_apply_role = bool
    allowed_branches  = optional(list(string))
  })
}
```

**Benefits:**
- Reduced duplication (1 variable instead of 7)
- Better organization (related variables grouped)
- Easier to pass between modules
- Clearer intent (all GitHub OIDC config in one place)

### Common Variables

All main modules declare only these essential variables:

- `project_name`: Project name for resource naming
- `environment`: Environment name (dev, stage, prod)

Environment-level `variables.tf` also includes:
- `aws_region`: AWS region (used for provider configuration)

### Layer-Specific Variables

**10_core** main module variables:
- `project_name`
- `environment`

**20_infra** main module variables:
- `project_name`
- `environment`
- `github_oidc_config`: GitHub OIDC configuration (grouped)
- `backend_config`: Terraform state backend config from 10_core (grouped)
- Lambda ARN variables: For integrating with 30_app layer (optional)

**30_app** main module variables:
- `project_name`
- `environment`
- `deploy_mode`: Deployment mode (zip or container)

### Variable Validation

All variables include validation blocks to ensure correctness:

```hcl
variable "environment" {
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}
```

This prevents invalid values from being passed and provides clear error messages.

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
   - Define secrets in `terraform.tfvars` using the `secrets` variable
   - Output secret ARNs for use in other layers

2. **20_infra**: Grants access permissions
   - IAM policies grant `secretsmanager:GetSecretValue` permission
   - Attach policies to Lambda execution roles
   - Reference secret ARNs from `10_core` outputs

3. **30_app**: Consumes secrets at runtime
   - Lambda functions read secrets via AWS SDK
   - Pass secret ARNs as environment variables
   - Never embed secret values directly

**See**: `shared/docs/architecture.md` for detailed secret management strategy and examples.

## Lambda Components and Modules

### Component Usage

Components are reusable building blocks located in `deploy/components/`:

- **`lambda_simple_package`**: Packages Lambda source code into zip files (supports hybrid packaging: archive_file or pre-built zip)
- **`lambda_fastapi_server`**: Creates FastAPI Lambda function
- **`lambda_cron_server`**: Creates cron Lambda function
- **`lambda_sqs_worker`**: Creates SQS worker Lambda with event source mapping

Each component has a README.md file with detailed usage examples and variable descriptions.

### Hybrid Packaging Approach

The `lambda_simple_package` component supports a **hybrid packaging workflow**:

1. **Simple Functions (No Dependencies)**: Uses Terraform's `archive_file` by default
   - No manual build step required
   - Terraform automatically packages during `terraform plan/apply`
   - Suitable for functions with only standard library imports

2. **Complex Functions (With Dependencies)**: Uses pre-built zip files from `cb build`
   - Run `cb build` first to install dependencies and create zip files
   - Set `use_prebuilt_zip = true` in Terraform configuration
   - Terraform will use the pre-built zip file instead of creating a new one

**See**: `shared/docs/cb-cli.md` for detailed hybrid packaging workflow documentation.

### Module Structure

Modules in `deploy/30_app/modules/` orchestrate components:

- **`runtime_code_modules`**: Packages all Lambda source code using `lambda_simple_package` component
- **`lambda_roles`**: Creates IAM execution roles for all Lambda functions
- **`api_server`**: Creates API Lambda using `lambda_fastapi_server` component
- **`cron_server`**: Creates cron Lambda using `lambda_cron_server` component
- **`worker`**: Creates worker Lambda using `lambda_sqs_worker` component

### Lambda Deployment Flow

```
src/lambda/
  ↓ (runtime_code_modules packages source code)
out/
  ↓ (api_server/cron_server/worker modules use components)
Lambda Functions
  ↓ (outputs ARNs for integration)
20_infra layer (API Gateway, EventBridge)
```

See individual module README files for detailed examples and configuration options.

## Documentation

For detailed documentation, see:

- **Terraform State & Backend**: `shared/docs/terraform-state-and-backend.md` - Comprehensive guide on Terraform state, backend, workflow, and remote state usage
- **Remote State Configuration**: `shared/docs/remote-state.md` - Detailed backend setup, bootstrap process, and remote state configuration
- **Architecture**: `shared/docs/architecture.md` - System architecture and design (includes Lambda module structure)
- **CI/CD**: `shared/docs/ci-cd.md` - GitHub Actions workflows and OIDC setup
- **OIDC Setup**: `shared/docs/oidc-setup.md` - Detailed AWS OIDC configuration guide
- **Testing**: `shared/docs/testing.md` - Infrastructure testing guide
- **cb CLI**: `shared/docs/cb-cli.md` - Developer CLI tool documentation

## Best Practices

1. **Always deploy in order**: Core → Infra → App
2. **Review plans before applying**: Use `terraform plan` before `terraform apply`
3. **Use version control**: Commit all `.tf` files, but **never commit**:
   - `terraform.tfstate` files
   - `terraform.tfvars` (use `.example` files)
   - `.terraform/` directories
4. **Environment isolation**: Keep environment-specific values in `terraform.tfvars`
5. **State management**: Never manually edit state files; use Terraform commands
6. **Secret management**: Use AWS Secrets Manager; never store secrets in code or variables
7. **Variable grouping**: Use object types to group related variables (see Variable Management section)

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
terraform init -backend-config=backend.tfvars -migrate-state
```

To reconfigure backend:
```bash
terraform init -backend-config=backend.tfvars -reconfigure
```

### Import Existing Resources

To import existing AWS resources:
```bash
terraform import <resource_type>.<resource_name> <resource_id>
```
