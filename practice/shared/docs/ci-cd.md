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

Configure these secrets in your GitHub repository:

- `AWS_ROLE_ARN`: IAM role ARN to assume via OIDC
- `AWS_REGION`: Target AWS region (e.g., `us-east-1`)
- `TF_STATE_BUCKET`: S3 bucket name for Terraform state
- `TF_LOCK_TABLE`: DynamoDB table name for state locking

### GitHub Environments

Create GitHub Environments for each deployment target:
- `dev`: Development environment (optional auto-approval)
- `stage`: Staging environment (requires approval)
- `prod`: Production environment (requires approval)

### AWS OIDC Setup

1. Create IAM OIDC Identity Provider:
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list <thumbprint>
   ```

2. Create IAM Role with Trust Policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:*"
           }
         }
       }
     ]
   }
   ```

3. Attach Policies:
   - Terraform state bucket access (S3)
   - State locking table access (DynamoDB)
   - Resource creation permissions (EC2, Lambda, API Gateway, etc.)

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
├── terraform-validate.yml  (Implemented)
├── terraform-plan.yml      (Implemented)
├── terraform-apply.yml     (TODO)
└── build-zip.yml           (TODO)
```

### Current Workflows

#### terraform-validate.yml
- **Status**: Implemented
- **Trigger**: Pull requests to any branch
- **Path Filters**: `practice/deploy/**`
- **Purpose**: Validates Terraform code quality and syntax
- **AWS Credentials**: Not required (uses `-backend=false`)
- **Matrix Strategy**: Runs validation for all three layers in parallel

See the workflow file for implementation details and inline comments explaining backend usage.

#### terraform-plan.yml
- **Status**: Implemented
- **Trigger**: Pull requests OR manual workflow dispatch
- **Path Filters**: `practice/deploy/**` (for PR trigger)
- **Purpose**: Generates Terraform execution plans for all environments
- **AWS Credentials**: Required (uses OIDC authentication)
- **Matrix Strategy**: Runs plans for all environments (dev, stage, prod) × selected layers
- **Manual Inputs**: Layer selection (all, 10_core, 20_infra, 30_app)
- **Artifacts**: Plan files uploaded with 7-day retention
- **Working Directory**: `practice/deploy/<layer>/environments/<env>/`

See the workflow file for implementation details and inline comments explaining backend usage.

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

Each environment uses `backend.tfvars`:

```hcl
bucket         = "tt-practice-tf-state-<unique>"
dynamodb_table = "tt-practice-tf-locks"
key            = "10_core/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
```

## Next Steps

1. [DONE] Document CI/CD approach
2. [DONE] Create Terraform Validate workflow
3. [DONE] Create Terraform Plan workflow (PR & manual dispatch)
4. [TODO] Create Terraform Apply workflow (manual dispatch with approvals)
5. [TODO] Create Build workflow for Lambda zip artifacts
6. [TODO] Set up OIDC provider and IAM roles
7. [TODO] Configure GitHub Environments
8. [TODO] Test workflows in dev environment
