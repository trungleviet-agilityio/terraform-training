# CI/CD for Terraform Practice (GitHub Actions)

This project uses GitHub Actions with AWS OIDC to validate, plan, and apply Terraform infrastructure changes.

## Workflow Overview

### Proposed Workflows

#### 1. Terraform Validate (PR)
**Trigger**: On pull requests to `main` branch  
**Purpose**: Validate Terraform code quality and syntax

**Steps**:
- Check Terraform formatting (`terraform fmt -check`)
- Initialize Terraform without backend (`terraform init -backend=false`)
- Validate Terraform syntax (`terraform validate`)
- Run TFLint for best practices (`tflint`)

**Targets**: All layers (`deploy/10_core`, `deploy/20_infra`, `deploy/30_app`)

#### 2. Terraform Plan (Manual)
**Trigger**: Manual workflow dispatch  
**Purpose**: Generate Terraform execution plan for review

**Inputs**:
- `layer`: Layer to plan (`10_core`, `20_infra`, `30_app`)
- `environment`: Environment name (`dev`, `stage`, `prod`)

**Steps**:
- Configure AWS credentials via OIDC
- Initialize Terraform with S3/DynamoDB backend
- Run `terraform plan` and upload plan artifact

#### 3. Terraform Apply (Manual with Approvals)
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
- Initialize Terraform with S3/DynamoDB backend
- Run `terraform apply`

#### 4. Build Workflow (Optional)

**build-zip**:
- Package Lambda layer with dependencies
- Package Lambda function code as zip
- Upload artifacts to GitHub Actions artifacts
- Optionally upload to S3 artifacts bucket for deployment

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

Workflows should be placed in `.github/workflows/`:

```
.github/workflows/
├── terraform-validate.yml
├── terraform-plan.yml
├── terraform-apply.yml
└── build-zip.yml
```

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
2. [TODO] Create GitHub Actions workflows
3. [TODO] Set up OIDC provider and IAM roles
4. [TODO] Configure GitHub Environments
5. [TODO] Add build workflow for Lambda zip artifacts
6. [TODO] Test workflows in dev environment
