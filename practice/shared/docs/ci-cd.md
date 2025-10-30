## CI/CD for Terraform Practice (GitHub Actions)

This project validates, plans, and applies Terraform for the serverless practice using GitHub Actions with AWS OIDC.

### Workflows (proposed)
- terraform-validate (PR):
  - Runs `terraform fmt -check`, `init -backend=false`, `validate`, and `tflint` for `practice/10_core`, `practice/20_infra`, and `practice/30_app`.
- terraform-plan (manual):
  - Inputs: `env_name` (dev|stage|prod)
  - Configures AWS via OIDC, runs `terraform init` with S3/DynamoDB backend, and `terraform plan`, uploads plan artifact.
- terraform-apply (manual with approvals):
  - Inputs: `env_name` (dev|stage|prod)
  - Protected by GitHub Environments; assumes AWS role via OIDC; runs `terraform apply`.
- Optional build workflows:
  - build-zip: package Lambda layer and function zips and upload artifacts or to artifacts S3 bucket.
  - build-container: build/push Lambda container image to ECR (tag = commit SHA).

### Required Secrets / Configuration
- `AWS_ROLE_ARN`: IAM role to assume from GitHub (via OIDC) with permissions to plan/apply.
- `AWS_REGION`: Target AWS region.
- `TF_STATE_BUCKET`: S3 bucket name for Terraform state.
- `TF_LOCK_TABLE`: DynamoDB table name for state locking.

### Environments
Each environment lives under `practice/envs/{dev,stage,prod}` and composes the layers. Backend config is supplied at runtime with `-backend-config` flags.

### Example Commands (Local)
```
cd practice/envs/dev
terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="dynamodb_table=$TF_LOCK_TABLE" \
  -backend-config="key=practice/dev/terraform.tfstate" \
  -backend-config="region=$AWS_REGION"
terraform plan -var="project_name=tt-practice" -var="aws_region=$AWS_REGION"
```

### Using cb (developer CLI)
```
# Build zip artifacts from default locations
practice/bin/cb build

# Deploy an environment (requires AWS_REGION, TF_STATE_BUCKET, TF_LOCK_TABLE)
AWS_REGION=us-east-1 TF_STATE_BUCKET=your-state-bucket TF_LOCK_TABLE=your-lock-table \
  practice/bin/cb deploy --env dev
```

### Next Steps
- Add the three workflows under `.github/workflows/` and wire required secrets.
- Optionally add build workflows or a root `cb` CLI to orchestrate build/test/deploy.
