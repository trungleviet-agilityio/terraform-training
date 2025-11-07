# Policies Module

This module creates IAM policies for both GitHub Actions (Terraform operations) and Lambda functions.

## Resources Created

### GitHub Actions Policies (optional - created if `policy_name_prefix` is provided)
- `aws_iam_policy.terraform_state_access`: Policy for S3 state bucket and DynamoDB state locking
- `aws_iam_policy.terraform_resource_creation`: Policy for creating/updating/deleting Terraform resources
- `aws_iam_policy.terraform_plan`: Policy for Terraform plan operations (read-only + state access)
- `aws_iam_policy.terraform_apply`: Policy for Terraform apply operations (full access + state access)

### Lambda Policies (always created if resources exist)
- `aws_iam_policy.lambda_dynamodb_access`: Policy for Lambda functions to access DynamoDB tables
- `aws_iam_policy.lambda_sqs_access`: Policy for Lambda functions to access SQS queues

## Usage

```hcl
module "iam_policies" {
  source = "../modules/policies"

  # GitHub Actions policy variables (optional)
  policy_name_prefix = "github-actions-terraform-dev"
  state_bucket_arn   = "arn:aws:s3:::my-terraform-state-bucket"
  dynamodb_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-locks"
  account_id         = "123456789012"
  region             = "us-east-1"

  # Lambda policy variables (always create)
  project_name       = "terraform-practice"
  environment        = "dev"
  dynamodb_table_arns = ["arn:aws:dynamodb:us-east-1:123456789012:table/my-table"]
  sqs_queue_arn      = "arn:aws:sqs:us-east-1:123456789012:my-queue"

  tags = {
    Project     = "terraform-practice"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| `policy_name_prefix` | `string` | Prefix for GitHub Actions IAM policy names. Empty string to skip GitHub Actions policies. | `""` | No |
| `state_bucket_arn` | `string` | ARN of the S3 bucket for Terraform state (required if creating GitHub Actions policies) | `""` | No |
| `dynamodb_table_arn` | `string` | ARN of the DynamoDB table for state locking (required if creating GitHub Actions policies) | `""` | No |
| `account_id` | `string` | AWS account ID (required if creating GitHub Actions policies) | `""` | No |
| `region` | `string` | AWS region (required if creating GitHub Actions policies) | `""` | No |
| `project_name` | `string` | Project name for Lambda policy naming | `""` | No |
| `environment` | `string` | Environment name for Lambda policy naming | `""` | No |
| `dynamodb_table_arns` | `list(string)` | List of DynamoDB table ARNs (for Lambda DynamoDB permissions) | `[]` | No |
| `sqs_queue_arn` | `string` | ARN of the SQS queue (for worker Lambda permissions) | `""` | No |
| `tags` | `map(string)` | Tags to apply to all policies | `{}` | No |

## Outputs

### GitHub Actions Policy Outputs
| Name | Description |
|------|-------------|
| `terraform_state_access_policy_arn` | ARN of the state access policy. Null if GitHub Actions policies not created. |
| `terraform_resource_creation_policy_arn` | ARN of the resource creation policy. Null if GitHub Actions policies not created. |
| `terraform_plan_policy_arn` | ARN of the plan policy. Null if GitHub Actions policies not created. |
| `terraform_apply_policy_arn` | ARN of the apply policy. Null if GitHub Actions policies not created. |

### Lambda Policy Outputs
| Name | Description |
|------|-------------|
| `lambda_dynamodb_access_policy_arn` | ARN of the DynamoDB access policy for Lambda functions. Null if no DynamoDB tables configured. |
| `lambda_sqs_access_policy_arn` | ARN of the SQS access policy for Lambda functions. Null if no SQS queue configured. |

## Policy Details

### Terraform State Access Policy

Grants permissions for:
- S3: `GetObject`, `PutObject`, `ListBucket` on state bucket
- DynamoDB: `GetItem`, `PutItem`, `DeleteItem`, `DescribeTable` on state lock table

### Terraform Resource Creation Policy

Grants permissions for Terraform-managed resources:
- **Lambda**: Create, update, delete functions, aliases, permissions
- **API Gateway v2**: Specific actions for HTTP API, stages, custom domains, integrations, routes (not wildcard)
- **DynamoDB**: Create, update, delete tables and tags
- **SQS**: Create, update, delete queues
- **EventBridge Scheduler**: Create, update, delete schedules (not Events rules)
- **Route53**: Create, update, delete hosted zones and DNS records
- **ACM**: Request, manage SSL/TLS certificates (including us-east-1 for API Gateway)
- **Secrets Manager**: Create, update, delete secrets (scoped to project name prefix)
- **KMS**: Manage existing keys and aliases (key creation removed for security)
- **CloudWatch Logs**: Create, update, delete log groups
- **IAM**: Create, update, delete roles and policies (for service roles)
- **PassRole**: Pass roles to AWS services (Lambda, API Gateway, EventBridge Scheduler)

### Terraform Plan Policy

Combines:
- State access permissions (full)
- Read-only resource permissions (Describe, List, Get operations)

### Terraform Apply Policy

Combines:
- State access permissions (full)
- Resource creation permissions (full)

## Security Considerations

- **Least Privilege**: Policies follow least-privilege principle with specific actions (no wildcards except where necessary)
- **API Gateway**: Uses specific `apigatewayv2:*` actions instead of `apigateway:*` wildcard
- **EventBridge**: Uses EventBridge Scheduler (`scheduler:*`) actions, not Events (`events:*`)
- **DynamoDB**: Permissions added for table creation in `20_infra` layer
- **Route53 & ACM**: Permissions added for DNS and certificate management in `10_core` layer
- **Secrets Manager**: Scoped to secrets with project name prefix (`${project_name}-*`)
- **KMS**: Key creation (`kms:CreateKey`) and deletion scheduling removed for security
- **IAM**: Broad permissions required for Terraform operations; consider adding resource restrictions in production
- **PassRole**: Restricted to specific services (Lambda, API Gateway, EventBridge Scheduler)
- **Resource ARNs**: Scoped to specific account and region where possible

## References

- [AWS IAM Policy Documents](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [Terraform AWS Provider: IAM Policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
