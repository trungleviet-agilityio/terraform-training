# CI/CD for Terraform (GitHub Actions)

GitHub Actions workflows for Terraform validation, planning, and deployment using AWS OIDC authentication.

## Workflows

### ci.yml (Terraform CI)
- **Trigger**: Pull requests
- **Purpose**: Validate Terraform code and generate plans
- **Path Filters**: `practice/deploy/**`, `.github/workflows/ci.yml`
- **Execution Model**: Sequential (10_core → 20_infra → 30_app)
- **Dependency Enforcement**: Workflows enforce sequential execution to respect layer dependencies:
  - `plan-20-infra` waits for `plan-10-core` to complete
  - `plan-30-app` waits for `plan-20-infra` to complete
  - This ensures remote state dependencies are available before planning dependent layers
- **Steps**:
  1. Detect changed layers (10_core, 20_infra, 30_app)
  2. Validate all changed layers in parallel:
     - `terraform fmt -check`
     - `terraform validate` (no backend)
  3. Plan changed layers sequentially:
     - Setup Terraform, AWS credentials, and retrieve secrets
     - Build Lambda packages (30_app only)
     - `terraform plan` (against dev environment)
  4. Post plan output as PR comment
- **Working Directory**: `practice/deploy/<layer>/environments/dev/`
- **AWS Credentials**: OIDC authentication with `terraform-plan` role

### apply.yml (Terraform Apply)
- **Trigger**: 
  - Push to `feat/terraform-practice` branch
  - Manual workflow dispatch
- **Purpose**: Apply Terraform changes
- **Path Filters**: `practice/deploy/**`, `.github/workflows/apply.yml`
- **Execution Model**: Sequential (10_core → 20_infra → 30_app)
- **Dependency Enforcement**: Workflows enforce sequential execution to respect layer dependencies:
  - `apply-20-infra` waits for `apply-10-core` to complete
  - `apply-30-app` waits for `apply-20-infra` to complete
  - This ensures remote state outputs are available before deploying dependent layers
- **Steps**:
  1. Detect changed layers and determine environment (default: dev)
  2. Apply changed layers sequentially:
     - Setup Terraform, AWS credentials, and retrieve secrets
     - Build Lambda packages (30_app only)
     - `terraform init`
     - `terraform validate`
     - `terraform plan`
     - `terraform apply -auto-approve`
- **Working Directory**: `practice/deploy/<layer>/environments/<env>/`
- **AWS Credentials**: OIDC authentication with `terraform-apply` role
- **Protection**: GitHub Environments for manual approval on stage/prod

### Composite Actions

Workflows leverage reusable composite actions for better maintainability:

**Setup Actions**:
- `.github/actions/setup-terraform`: Terraform setup, provider caching, AWS OIDC auth
- `.github/actions/setup-python-build`: Python and UV setup with caching (30_app only)

**Configuration Actions**:
- `.github/actions/get-terraform-secrets`: Retrieve variables and backend config from Secrets Manager

**Build Actions**:
- `.github/actions/build-lambda`: Build and verify Lambda packages (30_app only)

**Terraform Actions**:
- `.github/actions/terraform-plan`: Init, validate, and plan
- `.github/actions/terraform-apply`: Init, validate, plan, and apply

**Benefits**:
- DRY principle: Define once, use across all layers
- Consistency: Identical setup for all jobs
- Maintainability: Update logic in one place
- Readability: High-level orchestration in main workflows

## Configuration

### GitHub Secrets

**Repository-level secrets**:
- `AWS_ROLE_ARN`: IAM role ARN for OIDC (terraform-plan role for CI, terraform-apply role for apply)
- `AWS_REGION`: Target AWS region (e.g., `ap-southeast-1`)

**Environment-level secrets** (optional, per GitHub Environment):
- `AWS_ROLE_ARN`: Override role ARN per environment
- `AWS_REGION`: Override region per environment

**Note**: For `apply.yml`, set `AWS_ROLE_ARN` in GitHub Environment secrets to the `terraform-apply` role ARN. Keep repository-level `AWS_ROLE_ARN` as the `terraform-plan` role ARN.

### GitHub Environments

Configure environments in repository Settings → Environments:

- **dev**: Development (auto-approval enabled)
- **stage**: Staging (requires 1+ reviewers)
- **prod**: Production (requires 2+ reviewers)

### Backend Configuration

Backend configuration is automated via AWS Secrets Manager:

- **Secret**: `/practice/{env}/backend-bucket`
- **Format**: `{"bucket": "bucket-name"}`
- **Creation**: Automatically created by `10_core` layer
- **Usage**: Workflows retrieve bucket name before `terraform init`
- **Fallback**: Constructs bucket name from pattern if secret doesn't exist

### Terraform Variables

Terraform variables are managed via AWS Secrets Manager for CI/CD:

- **Secrets**: `/practice/{env}/{layer}/terraform-vars`
- **Format**: JSON with selected Terraform variable values (not all variables)
- **Creation**: Automatically created by `10_core` layer
- **Usage**: Workflows retrieve and set as `TF_VAR_*` environment variables (lowercase format, matching variable names)
- **Local Development**: Use `.env` file with `TF_VAR_*` variables (lowercase format) or `terraform.tfvars` (gitignored)

#### Variable Selection Criteria

**Variables stored in Secrets Manager** (only those that):
- Vary by environment (dev/stage/prod have different values)
- Required for CI/CD consistency
- Not retrieved from remote state automatically

**Variables NOT stored** (use defaults or remote state):
- Variables with good default values
- Variables retrieved from remote state automatically (e.g., `backend_config`)
- Variables that rarely change across environments

#### Variables Stored by Layer

**10_core layer** (`/practice/{env}/10_core/terraform-vars`):
- `aws_region`
- `project_name`
- `environment`
- `dns_config`
- `use_us_east_1_certificate`

**20_infra layer** (`/practice/{env}/20_infra/terraform-vars`):
- `aws_region` (common)
- `project_name` (common)
- `environment` (common)
- `github_oidc_config` (must be added separately via AWS Console/CLI)
- `dynamodb_tables` (must be added separately via AWS Console/CLI)

**30_app layer** (`/practice/{env}/30_app/terraform-vars`):
- `aws_region` (common)
- `project_name` (common)
- `environment` (common)
- `eventbridge_schedule_expression` (must be added separately via AWS Console/CLI)
- `deploy_mode` (optional, must be added separately if needed)

**Note**: `10_core` layer creates secrets with common variables only. Layer-specific variables (e.g., `github_oidc_config`, `dynamodb_tables`) must be added manually via AWS Console or CLI after secret creation.

**Example `.env` file**:
```bash
export TF_VAR_aws_region="ap-southeast-1"
export TF_VAR_project_name="tt-practice"
export TF_VAR_environment="dev"
export TF_VAR_github_oidc_config='{"organization":"trungleviet-agilityio","repository":"terraform-training","create_oidc":true,"create_policies":true,"create_plan_role":true,"create_apply_role":true}'
export TF_VAR_dynamodb_tables='{"user-data":{"partition_key":"user_id","type":"key-value","attribute_types":{"user_id":"S"},"enable_point_in_time_recovery":true},"events":{"partition_key":"event_type","sort_key":"timestamp","type":"time-series","attribute_types":{"event_type":"S","timestamp":"N"},"enable_ttl":true,"ttl_attribute":"ttl"}}'
export TF_VAR_eventbridge_schedule_expression="rate(5 minutes)"
```

**Note**: Terraform automatically maps `TF_VAR_*` environment variables to variable names (e.g., `TF_VAR_aws_region` → `aws_region`). Use lowercase format matching the variable name.

## AWS OIDC Setup

OIDC provider and IAM roles are managed via Terraform in the `20_infra` layer:

- **OIDC Provider**: Created by `20_infra/modules/oidc-provider`
- **IAM Policies**: Created by `20_infra/modules/policies` (terraform-plan, terraform-apply)
- **IAM Roles**: Created by `20_infra/modules/roles` (terraform-plan, terraform-apply)

**Setup Steps**:
1. Deploy `10_core` layer to create state backend
2. Configure `20_infra` with GitHub OIDC settings in `terraform.tfvars`
3. Deploy `20_infra` layer to create OIDC provider and IAM roles
4. Add GitHub Secrets (`AWS_ROLE_ARN`, `AWS_REGION`)
5. Test workflow execution

## Permission Differences: Local vs CI/CD

**Local Development**:
- Uses AWS credentials with broader permissions (admin/root)
- Terraform can read all resource configurations

**CI/CD**:
- Uses OIDC authentication with restricted `terraform-plan`/`terraform-apply` roles
- Follows least-privilege principle
- Must explicitly grant all read permissions Terraform needs

**Common Permission Issues**:
- S3 bucket configuration reads (website, CORS, logging, etc.)
- IAM policy version reads
- Resource refresh operations

**Best Practices**:
- Test workflows in CI/CD, not just locally
- Use least-privilege permissions scoped to specific resources
- Monitor CloudTrail logs for AccessDenied errors

## State Management

### State File Structure

Each environment uses a separate S3 bucket, with each layer having its own state file:

```
s3://tt-practice-tf-state-{env}-{account-id}/
├── core/terraform.tfstate      (10_core layer)
├── infra/terraform.tfstate    (20_infra layer)
└── app/terraform.tfstate       (30_app layer)
```

**Bucket naming pattern**: `tt-practice-tf-state-{environment}-{account-id}`
- Example: `tt-practice-tf-state-dev-057336397237`
- Each environment (dev/stage/prod) has its own bucket
- All layers within an environment share the same bucket

### State Locking

DynamoDB table provides state locking:
- **Table**: `tt-practice-tf-locks`
- **Primary Key**: `LockID`
- **Billing Mode**: Pay-per-request

## Local Development

### Using Terraform CLI

```bash
cd practice/deploy/10_core/environments/dev

# Source environment variables
source ../../../../.env

# Initialize with backend
terraform init -backend-config="bucket=$TF_STATE_BUCKET"

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Variable Management

- **Local**: Use `.env` file with `TF_VAR_*` variables (lowercase format, matching variable names) or `terraform.tfvars` (gitignored, local only)
- **CI/CD**: Reads from AWS Secrets Manager (`/practice/{env}/{layer}/terraform-vars`)
- **Consistency**: Secrets Manager contains same variables as local `.env` or `terraform.tfvars`
- **Generation**: Use `practice/bin/generate-env-example` to generate `.env.example` from `terraform.tfvars.example` files

**Local Development Options**:
1. Use `.env` file: `source .env` before running Terraform commands
2. Use `terraform.tfvars`: Copy `terraform.tfvars.example` to `terraform.tfvars` (gitignored) and customize

**Note**: `terraform.tfvars` files are gitignored and kept locally only. They are not used in CI/CD workflows.

## Workflow File Structure

```
.github/workflows/
├── ci.yml          # PR validation and planning
└── apply.yml       # Auto-deploy on feat/terraform-practice
```

## Best Practices

1. Always review plans before applying
2. Use environment protection for production
3. Deploy layers in order: 10_core → 20_infra → 30_app
4. Never commit state files or secrets
5. Use OIDC authentication (no static credentials)

## See Also

- [Architecture Documentation](architecture.md) - System architecture overview
- [Remote State Documentation](remote-state.md) - Terraform state management
- [Operations Runbook](runbook.md) - Rollback procedures, log inspection, and troubleshooting
