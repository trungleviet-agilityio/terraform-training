# CI/CD for Terraform Practice (GitHub Actions)

This project uses GitHub Actions with AWS OIDC to validate, plan, and apply Terraform infrastructure changes.

## Workflow Overview

### Proposed Workflows

#### 1. Terraform Validate (PR)
**Trigger**: On pull requests to all branches  
**Purpose**: Validate Terraform code quality and syntax

**Path Filters**: Only runs when files in `practice/deploy/**` are changed

**Steps**:
- Check Terraform formatting (`terraform fmt -check`)
- Initialize Terraform without backend (`terraform init -backend=false`)
- Validate Terraform syntax (`terraform validate`)
- Run TFLint for best practices (`tflint`)

**Targets**: All layers (`deploy/10_core`, `deploy/20_infra`, `deploy/30_app`)

**Implementation**: `.github/workflows/terraform-validate.yml`

**Features**:
- Matrix strategy runs validation in parallel for all layers
- No AWS credentials required (uses `-backend=false`)
- Fast execution (no S3 network calls)
- Fails fast if any layer fails validation

#### 2. Terraform Plan (PR & Manual) IMPLEMENTED
**Trigger**: Pull requests OR manual workflow dispatch  
**Purpose**: Generate Terraform execution plan for review

**Path Filters**: Only runs when files in `practice/deploy/**` are changed (for PR trigger)

**Manual Dispatch Inputs**:
- `layer`: Layer to plan (`10_core`, `20_infra`, `30_app`, or `all`)
- Default: `all` (runs for all layers)

**Steps**:
- Configure AWS credentials via OIDC
- Initialize Terraform with S3/DynamoDB backend (uses `terraform init` with backend=true)
- Run `terraform plan` and upload plan artifact

**Targets**: All environments (dev, stage, prod) × selected layers

**Implementation**: `.github/workflows/terraform-plan.yml`

**Features**:
- Matrix strategy runs plans in parallel for all environments
- Dynamic layer selection via prepare job
- Plan artifacts uploaded for review (7-day retention)
- AWS credentials required (uses OIDC authentication)
- Reads state from S3 backend

#### 3. Terraform Apply (Manual with Approvals) TODO
**Trigger**: Manual workflow dispatch  
**Purpose**: Apply Terraform changes to infrastructure

**Inputs**:
- `layer`: Layer to apply (`10_core`, `20_infra`, `30_app`)
- `environment`: Environment name (`dev`, `stage`, `prod`)

**Protection**: 
- Uses GitHub Environments for approval gates
- Requires manual approval for `stage` and `prod`
- Auto-approve for `dev` (optional)

**Steps**:
- Configure AWS credentials via OIDC
- Initialize Terraform with S3/DynamoDB backend (uses `terraform init` with backend=true)
- Run `terraform apply`

**Note**: This workflow will require AWS credentials, S3 backend access, and permissions to create/modify AWS resources.

#### 4. Build Workflow (Optional) TODO

**build-zip**:
- Package Lambda layer with dependencies using UV
- Package Lambda function code as zip
- Upload artifacts to GitHub Actions artifacts
- Optionally upload to S3 artifacts bucket for deployment

**Note**: This workflow can leverage the `cb` CLI tool's build functionality. See `shared/docs/cb-cli.md` for details.

## Required Configuration

### GitHub Secrets

Configure these secrets in your GitHub repository (repository-level or environment-level):

**Repository-level secrets** (shared across all environments):
- `AWS_ROLE_ARN`: IAM role ARN to assume via OIDC (terraform-apply role from 20_infra outputs)
- `AWS_REGION`: Target AWS region (e.g., `ap-southeast-1`)

**Optional: Environment-specific secrets** (configured per GitHub Environment):
- `AWS_ROLE_ARN`: Override role ARN per environment (e.g., different roles for dev/prod)
- `AWS_REGION`: Override region per environment

**Note**: If using AWS Secrets Manager for additional secrets (e.g., backend bucket names, API keys), the workflow will automatically retrieve them using the OIDC role permissions. Ensure the IAM role has `secretsmanager:GetSecretValue` permissions for the required secrets.

### Backend Configuration via AWS Secrets Manager

**Automated Backend Configuration:**
- The `10_core` layer automatically creates a secret `/practice/{env}/backend-bucket` when deployed
- This secret stores the Terraform state backend S3 bucket name in JSON format: `{"bucket": "bucket-name"}`
- CI/CD workflows automatically retrieve the bucket name from Secrets Manager before initializing Terraform
- No manual configuration or `backend.tfvars` files needed in version control

**How It Works:**
1. When `10_core` layer is deployed, it creates the secret automatically
2. Workflows retrieve bucket name from `/practice/{env}/backend-bucket` secret
3. Bucket name is used in `terraform init -backend-config="bucket={name}"`
4. Fallback: If secret doesn't exist, workflows construct bucket name from pattern: `tt-practice-tf-state-{env}-{account-id}`

**Benefits:**
- Fully automated - no manual steps required
- Single source of truth - Secrets Manager is authoritative
- Secure - bucket names not committed to version control
- Environment isolation - separate secrets per environment
- Audit trail - all access logged in CloudTrail

### GitHub Environments

GitHub Environments is a feature that allows environment-specific configuration and protection rules. Set up environments in your repository settings:

**Setup Steps**:
1. Go to repository Settings → Environments
2. Create environments: `dev`, `stage`, `prod`
3. For each environment:
   - **Secrets**: Add environment-specific secrets (optional, falls back to repository secrets)
   - **Protection rules** (for `stage` and `prod`):
     - ✅ Required reviewers (add team members who must approve deployments)
     - ✅ Wait timer (optional delay before deployment)
     - ✅ Deployment branches (restrict to specific branches)

**Environment Configuration**:
- `dev`: Development environment
  - Auto-approval: Enabled (no reviewers required)
  - Use for: Testing and development
- `stage`: Staging environment
  - Required reviewers: 1+ team members
  - Use for: Pre-production testing
- `prod`: Production environment
  - Required reviewers: 2+ team members (recommended)
  - Use for: Production deployments

**How it works**:
- The workflow references environments using `environment: ${{ needs.detect-changes.outputs.environment }}`
- GitHub will pause the workflow and request approval before deploying to protected environments
- Approvers receive notifications and can approve/reject from the GitHub Actions UI

### AWS OIDC Setup

The AWS OIDC setup is managed via Terraform in the `20_infra` layer. This eliminates the need for manual setup and ensures consistency across environments.

**For detailed setup instructions, see: [OIDC Setup Guide](oidc-setup.md)**

**Quick Summary**:
1. Deploy `10_core` layer to create state backend
2. Configure `20_infra` with GitHub OIDC settings
3. Deploy `20_infra` layer to create OIDC provider and IAM roles
4. Add GitHub Secrets (`AWS_ROLE_ARN`, `AWS_REGION`)
5. Test workflow execution

**Components**:
- OIDC Provider Module: Creates AWS IAM OIDC identity provider
- Policies Module: Creates IAM policies (state access, plan, apply)
- Roles Module: Creates IAM roles with trust policies (plan + apply)

## Permission Differences: Local vs CI/CD

**Why local development works but CI/CD fails:**

Local development typically uses AWS credentials with broader permissions (admin/root or full access), while CI/CD uses the `terraform-plan` role with restricted least-privilege permissions. This is by design for security, but requires careful permission management.

**Key Differences:**

1. **Local Development:**
   - Uses AWS credentials from `~/.aws/credentials` or environment variables
   - Often has admin/root access or broad permissions
   - Terraform can read all resource configurations without permission errors
   - Suitable for development and testing

2. **CI/CD (GitHub Actions):**
   - Uses OIDC authentication with restricted `terraform-plan` role
   - Follows least-privilege principle - only grants necessary permissions
   - Must explicitly grant all read permissions Terraform needs
   - Terraform's AWS provider reads ALL resource configurations during refresh, even if not explicitly configured

**Common Permission Issues:**

- **S3 Bucket Configuration**: Terraform reads all bucket configurations (website, CORS, logging, etc.) during refresh, even if not explicitly configured. The `terraform-plan` policy uses `s3:GetBucket*` wildcard to cover all bucket read operations.

- **IAM Policy Versions**: When IAM policies have multiple versions, Terraform needs `iam:GetPolicyVersion` to read the current version.

- **Resource Refresh**: Terraform refreshes state by reading current resource configurations. All read permissions must be granted, even for resources that aren't being modified.

**Best Practices:**

- Always test workflows in CI/CD, not just locally
- Use least-privilege permissions scoped to specific resources
- Use wildcards for read operations when scoped to specific resources (e.g., `s3:GetBucket*` for state bucket only)
- Monitor CloudTrail logs for AccessDenied errors and add missing permissions as needed

## Local Development

### Using Terraform CLI

```bash
cd deploy/10_core/environments/dev

# Initialize with backend
terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="dynamodb_table=$TF_LOCK_TABLE" \
  -backend-config="key=10_core/dev/terraform.tfstate" \
  -backend-config="region=$AWS_REGION"

# Plan changes
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

### Using cb CLI

```bash
# Build zip artifacts
practice/bin/cb build

# Deploy an environment (requires environment variables)
export AWS_REGION=us-east-1
export TF_STATE_BUCKET=your-state-bucket
export TF_LOCK_TABLE=your-lock-table

practice/bin/cb deploy --env dev
```

## Workflow File Structure

Workflows are placed in `.github/workflows/`:

```
.github/workflows/
├── ci.yml                  (Implemented - PR validation)
├── apply.yml               (Implemented - Auto-deploy on feat/terraform-practice)
└── build-zip.yml           (TODO)
```

### Current Workflows

#### ci.yml (Terraform CI)
- **Status**: Implemented
- **Trigger**: Pull requests (any branch)
- **Path Filters**: `practice/deploy/**`, `.github/workflows/ci.yml`
- **Purpose**: Validates Terraform code quality, syntax, and generates plans for review
- **AWS Credentials**: Required (uses OIDC authentication with terraform-apply role)
- **Matrix Strategy**: Runs validation for changed layers only
- **Steps**:
  1. Detect changed layers (10_core, 20_infra, 30_app)
  2. For each changed layer:
     - `terraform fmt -check` (formatting validation)
     - `terraform init -backend=false` (no backend needed)
     - `terraform validate` (syntax validation)
     - `terraform plan` (against dev environment)
  3. Post plan output as PR comment
- **Working Directory**: `practice/deploy/<layer>/environments/dev/`

#### apply.yml (Terraform Apply)
- **Status**: ✅ Implemented
- **Trigger**: 
  - Push to `feat/terraform-practice` branch
  - Manual workflow dispatch (with optional layer/environment inputs)
- **Path Filters**: `practice/deploy/**`, `.github/workflows/apply.yml`
- **Purpose**: Automatically applies Terraform changes after merge to main branch
- **AWS Credentials**: Required (uses OIDC authentication)
- **Environment**: Uses GitHub Environments (dev/stage/prod) for protection rules
- **Matrix Strategy**: Runs apply for changed layers only
- **Steps**:
  1. Detect changed layers and determine environment (default: dev)
  2. For each changed layer:
     - `terraform init -backend-config=backend.tfvars`
     - `terraform validate`
     - `terraform plan`
     - `terraform apply -auto-approve`
- **Working Directory**: `practice/deploy/<layer>/environments/<env>/`
- **Protection**: Uses GitHub Environments for manual approval on stage/prod

#### terraform-plan.yml (Legacy)
- **Status**: Implemented (may be replaced by ci.yml)
- See workflow file for details

#### terraform-apply.yml (Legacy)
- **Status**: Implemented (may be replaced by apply.yml)
- See workflow file for details

### Plan Artifacts

Plan artifacts generated by the `terraform-plan.yml` workflow:
- **Naming**: `terraform-plan-<layer>-<env>-<run-id>`
- **Retention**: 7 days
- **Location**: Downloadable from GitHub Actions artifacts
- **Usage**: Can be reviewed before applying, or used by apply workflow
- **Format**: Binary Terraform plan files (`.tfplan`)

### Adding New Workflows

When adding new workflows, follow these patterns:

1. **Reuse Matrix Strategy**: The validate workflow uses a matrix strategy over layers - consider reusing this pattern for plan/apply workflows
2. **Path Filters**: Use path filters to ensure workflows only run when relevant files change
3. **Backend Usage**: 
   - Use `terraform init -backend=false` for validation (no AWS access needed)
   - Use `terraform init` (default, backend=true) for plan/apply (requires AWS credentials and S3 access)
4. **Working Directory**: 
   - Set `working-directory` to `practice/deploy/${{ matrix.layer }}/main` for layer-level operations (validate)
   - Set `working-directory` to `practice/deploy/${{ matrix.layer }}/environments/${{ matrix.environment }}` for environment-level operations (plan/apply)
5. **Environment Handling**: For plan/apply workflows, use GitHub Environments for approval gates
6. **AWS Authentication**: Use AWS OIDC authentication (no static credentials)
7. **Matrix Strategy**: Use prepare job for dynamic matrix generation when manual inputs are involved

See the existing `terraform-validate.yml` as a reference implementation.

## Best Practices

1. **Always review plans**: Review `terraform plan` output before applying
2. **Use environment protection**: Require approvals for production
3. **Separate state per layer**: Each layer maintains its own state file
4. **Deploy in order**: Core → Infra → App
5. **Version control**: Never commit state files or secrets
6. **Use OIDC**: Avoid static AWS credentials in CI/CD

## State Management

### State File Structure

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

### Backend Configuration

Backend configuration is now managed via AWS Secrets Manager:

**Secret Location**: `/practice/{environment}/backend-bucket`

**Secret Format**: JSON string containing bucket name
```json
{
  "bucket": "tt-practice-tf-state-dev-057336397237"
}
```

**How It Works:**
1. `10_core` layer automatically creates the secret when deployed
2. CI/CD workflows retrieve bucket name from Secrets Manager
3. Bucket name is passed to `terraform init` via `-backend-config="bucket={name}"`
4. Fallback: If secret doesn't exist, workflows construct bucket name from pattern

**Workflow Implementation:**
```yaml
- name: Get backend bucket name from Secrets Manager
  run: |
    SECRET_NAME="/practice/${ENVIRONMENT}/backend-bucket"
    SECRET_VALUE=$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_NAME" \
      --query SecretString --output text)
    BUCKET_NAME=$(echo "$SECRET_VALUE" | jq -r '.bucket')
    terraform init -backend-config="bucket=${BUCKET_NAME}"
```

**Note**: `backend.tfvars` files are no longer needed and should not be committed to version control. They are automatically generated from Secrets Manager during workflow execution.

## AWS Secrets Manager Integration

The workflows can retrieve secrets from AWS Secrets Manager if needed. This is useful for:
- Backend configuration (S3 bucket names, DynamoDB table names)
- Terraform variable values (API keys, database credentials)
- Environment-specific configuration

### Using Secrets Manager in Workflows

**Example**: Retrieve backend bucket name from Secrets Manager:

```yaml
- name: Get Backend Bucket from Secrets Manager
  run: |
    BUCKET_NAME=$(aws secretsmanager get-secret-value \
      --secret-id /practice/${{ env.ENVIRONMENT }}/backend-bucket \
      --query SecretString --output text)
    echo "BUCKET_NAME=$BUCKET_NAME" >> $GITHUB_ENV
```

**IAM Permissions**: Ensure the OIDC role has `secretsmanager:GetSecretValue` permission for the required secrets. This is already included in the terraform-apply policy created by the `20_infra` layer.

**Secret Naming Convention**: Secrets follow the pattern `/practice/<environment>/<secret-name>` (as defined in `10_core/modules/secrets`).

### Backend Configuration via Secrets Manager

**Current Implementation (Automated):**

The workflows now use AWS Secrets Manager for backend configuration:

1. **Secret Creation**: `10_core` layer automatically creates `/practice/{env}/backend-bucket` secret
2. **Secret Retrieval**: Workflows retrieve bucket name from Secrets Manager before `terraform init`
3. **Backend Initialization**: Bucket name is passed via `-backend-config="bucket={name}"` flag
4. **Fallback**: If secret doesn't exist, workflows construct bucket name from pattern

**Example Workflow Step:**
```yaml
- name: Get backend bucket name from Secrets Manager
  run: |
    SECRET_NAME="/practice/${ENVIRONMENT}/backend-bucket"
    if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" &>/dev/null; then
      SECRET_VALUE=$(aws secretsmanager get-secret-value \
        --secret-id "$SECRET_NAME" \
        --query SecretString --output text)
      BUCKET_NAME=$(echo "$SECRET_VALUE" | jq -r '.bucket')
    else
      # Fallback: construct from pattern
      ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
      BUCKET_NAME="tt-practice-tf-state-${ENVIRONMENT}-${ACCOUNT_ID}"
    fi
    terraform init -backend-config="bucket=${BUCKET_NAME}"
```

**Benefits:**
- Fully automated - no manual configuration needed
- Secure - bucket names not in version control
- Environment-specific - separate secrets per environment
- Single source of truth - Secrets Manager is authoritative

## Next Steps

1. [DONE] Document CI/CD approach
2. [DONE] Create Terraform CI workflow (ci.yml)
3. [DONE] Create Terraform Apply workflow (apply.yml)
4. [DONE] Implement AWS Secrets Manager backend configuration
5. [DONE] Configure GitHub Environments (dev/stage/prod) in repository settings
6. [DONE] Add GitHub Secrets (AWS_ROLE_ARN, AWS_REGION)
7. [TODO] Deploy 10_core layer to create backend bucket secret
8. [TODO] Test workflows in dev environment
9. [TODO] Create Build workflow for Lambda zip artifacts
