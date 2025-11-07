# Roles Module

This module creates IAM roles for both GitHub Actions (Terraform operations) and Lambda functions.

## Resources Created

### GitHub Actions Roles (optional - created if `create_terraform_plan_role` or `create_terraform_apply_role` is true)
- `aws_iam_role.terraform_plan`: IAM role for Terraform plan operations (read-only)
- `aws_iam_role.terraform_apply`: IAM role for Terraform apply operations (full access)
- `aws_iam_role_policy_attachment`: Policy attachments for GitHub Actions roles

### Lambda Roles (always created if `create_lambda_roles` is true)
- `aws_iam_role.api_lambda_role`: IAM role for API Lambda function
- `aws_iam_role.cron_lambda_role`: IAM role for Cron Lambda function
- `aws_iam_role.worker_lambda_role`: IAM role for Worker Lambda function
- `aws_iam_role_policy_attachment`: Policy attachments for Lambda roles (basic execution, DynamoDB, SQS)

## Usage

```hcl
module "iam_roles" {
  source = "../modules/roles"

  # GitHub Actions role variables (optional)
  oidc_provider_arn        = module.oidc_provider.oidc_provider_arn
  github_organization      = "my-org"
  github_repository        = "terraform-training"
  create_terraform_plan_role = true
  create_terraform_apply_role = true
  terraform_plan_policy_arn = module.iam_policies.terraform_plan_policy_arn
  terraform_apply_policy_arn = module.iam_policies.terraform_apply_policy_arn
  allowed_branches         = ["main", "develop"]

  # Lambda role variables (always create)
  create_lambda_roles = true
  project_name        = "terraform-practice"
  environment         = "dev"
  lambda_policies = {
    lambda_dynamodb_access_policy_arn = module.iam_policies.lambda_dynamodb_access_policy_arn
    lambda_sqs_access_policy_arn      = module.iam_policies.lambda_sqs_access_policy_arn
  }

  tags = {
    Project     = "terraform-practice"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

### GitHub Actions Variables (optional)
| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| `oidc_provider_arn` | `string` | ARN of the OIDC provider (required if creating GitHub Actions roles) | `""` | No |
| `github_organization` | `string` | GitHub organization name (required if creating GitHub Actions roles) | `""` | No |
| `github_repository` | `string` | GitHub repository name (required if creating GitHub Actions roles) | `""` | No |
| `create_terraform_plan_role` | `bool` | Whether to create the plan role | `false` | No |
| `create_terraform_apply_role` | `bool` | Whether to create the apply role | `false` | No |
| `terraform_plan_role_name` | `string` | Name of the plan role | `github-actions-terraform-plan` | No |
| `terraform_apply_role_name` | `string` | Name of the apply role | `github-actions-terraform-apply` | No |
| `terraform_plan_policy_arn` | `string` | ARN of the plan policy (required if creating plan role) | `""` | No |
| `terraform_apply_policy_arn` | `string` | ARN of the apply policy (required if creating apply role) | `""` | No |
| `allowed_branches` | `list(string)` | Optional list of allowed branches | `null` | No |

### Lambda Variables (required if creating Lambda roles)
| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| `create_lambda_roles` | `bool` | Whether to create Lambda execution roles | `false` | No |
| `project_name` | `string` | Project name for Lambda role naming | `""` | No |
| `environment` | `string` | Environment name for Lambda role naming | `""` | No |
| `lambda_policies` | `object` | IAM policies for Lambda roles (from policies module) | `{}` | No |
| `tags` | `map(string)` | Tags to apply to roles | `{}` | No |

## Outputs

### GitHub Actions Role Outputs
| Name | Description |
|------|-------------|
| `terraform_plan_role_arn` | ARN of the Terraform plan role (use in GitHub Secret `AWS_ROLE_ARN`). Null if not created. |
| `terraform_apply_role_arn` | ARN of the Terraform apply role. Null if not created. |
| `terraform_plan_role_name` | Name of the Terraform plan role. Null if not created. |
| `terraform_apply_role_name` | Name of the Terraform apply role. Null if not created. |

### Lambda Role Outputs
| Name | Description |
|------|-------------|
| `lambda_api_role_arn` | ARN of the IAM role for API Lambda function |
| `lambda_api_role_name` | Name of the IAM role for API Lambda function |
| `lambda_cron_role_arn` | ARN of the IAM role for Cron Lambda function |
| `lambda_cron_role_name` | Name of the IAM role for Cron Lambda function |
| `lambda_worker_role_arn` | ARN of the IAM role for Worker Lambda function |
| `lambda_worker_role_name` | Name of the IAM role for Worker Lambda function |

## Trust Policy

The trust policy allows GitHub Actions from your repository to assume the role:

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

### Branch Restrictions

If `allowed_branches` is provided, the trust policy will restrict role assumption to specific branches:

```json
{
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub": [
        "repo:OWNER/REPO:ref:refs/heads/main",
        "repo:OWNER/REPO:ref:refs/heads/develop"
      ]
    }
  }
}
```

## Security Considerations

- **Least Privilege**: Plan role has read-only permissions; Apply role has full permissions
- **Repository Scoping**: Trust policy restricts access to your specific repository
- **Branch Restrictions**: Optionally restrict role assumption to specific branches
- **Audit Trail**: All role assumptions are logged in CloudTrail

## GitHub Actions Usage

After creating the roles, configure GitHub Secrets:

1. **For Plan Workflow** (`terraform-plan.yml`):
   - Secret: `AWS_ROLE_ARN` = `terraform_plan_role_arn` output
   - Secret: `AWS_REGION` = Your AWS region

2. **For Apply Workflow** (`terraform-apply.yml`):
   - Secret: `AWS_ROLE_ARN` = `terraform_apply_role_arn` output
   - Secret: `AWS_REGION` = Your AWS region

Example workflow step:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: ${{ secrets.AWS_REGION }}
```

## References

- [AWS Documentation: Creating Roles for OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)
- [GitHub Actions: Configuring OpenID Connect in AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
