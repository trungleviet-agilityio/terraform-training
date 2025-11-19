# Policies Module

This module creates IAM policies for both GitHub Actions (Terraform operations) and Lambda functions.

## Resources Created

### GitHub Actions Policies (optional - created if `policy_name_prefix` is provided)
- `aws_iam_policy.terraform_plan`: Policy for Terraform plan operations (read-only resource access + state access)
- `aws_iam_policy.terraform_apply`: Policy for Terraform apply operations (full resource access + state access)

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
| `terraform_plan_policy_arn` | ARN of the plan policy (read-only + state access). Null if GitHub Actions policies not created. |
| `terraform_apply_policy_arn` | ARN of the apply policy (full access + state access). Null if GitHub Actions policies not created. |
| `terraform_plan_policy_name` | Name of the plan policy. Null if GitHub Actions policies not created. |
| `terraform_apply_policy_name` | Name of the apply policy. Null if GitHub Actions policies not created. |

### Lambda Policy Outputs
| Name | Description |
|------|-------------|
| `lambda_dynamodb_access_policy_arn` | ARN of the DynamoDB access policy for Lambda functions. Null if no DynamoDB tables configured. |
| `lambda_sqs_access_policy_arn` | ARN of the SQS access policy for Lambda functions. Null if no SQS queue configured. |

## Policy Details

### Terraform Plan Policy

Grants permissions for:
- **State Access**: 
  - S3: `GetObject`, `PutObject`, `ListBucket`, `GetBucket*` (wildcard covers all bucket configuration read operations like GetBucketWebsite, GetBucketCors, GetBucketVersioning, etc.)
  - DynamoDB: `GetItem`, `PutItem`, `DeleteItem`, `DescribeTable`, `DescribeTimeToLive` for state locking
- **Read-Only Resource Access**: Describe, List, Get operations for all Terraform-managed resources:
  - Lambda, API Gateway, SQS, DynamoDB, EventBridge Scheduler, Route53, ACM, Secrets Manager, KMS, CloudWatch Logs
  - IAM: `GetRole`, `GetPolicy`, `GetPolicyVersion`, `GetOpenIDConnectProvider`, and related read operations

### Terraform Apply Policy

Grants permissions for:
- **State Access**: Full S3 and DynamoDB access for state management (same as plan policy)
- **Full Resource Access**: Create, update, delete operations for Terraform-managed resources:
  - **Lambda**: Create, update, delete functions, aliases, permissions
  - **API Gateway v2**: Specific actions for HTTP API, stages, custom domains, integrations, routes
  - **DynamoDB**: Create, update, delete tables and tags
  - **SQS**: Create, update, delete queues
  - **EventBridge Scheduler**: Create, update, delete schedules
  - **Route53**: Create, update, delete hosted zones and DNS records
  - **ACM**: Request, manage SSL/TLS certificates (including us-east-1 for API Gateway)
  - **Secrets Manager**: Create, update, delete secrets (scoped to `/practice/*` pattern and project prefix)
  - **KMS**: Manage existing keys and aliases (key creation removed for security)
  - **CloudWatch Logs**: Create, update, delete log groups
  - **IAM**: Create, update, delete roles and policies (restricted to project-managed resources when `project_name` is provided)
  - **PassRole**: Pass roles to AWS services (restricted to project-named roles when `project_name` is provided)

## Security Considerations

- **Least Privilege**: Policies follow least-privilege principle with specific actions (wildcards used only where necessary and scoped to specific resources)
- **S3 Bucket Read Operations**: Uses `s3:GetBucket*` wildcard for bucket-level read operations (scoped to state bucket ARN only). This is necessary because Terraform's AWS provider reads ALL bucket configurations during refresh (website, CORS, logging, etc.), even if not explicitly configured. The wildcard avoids missing permission issues while maintaining least privilege at the resource level.
- **API Gateway**: Uses `apigatewayv2:*` wildcard (scoped to API Gateway resources only)
- **EventBridge**: Uses EventBridge Scheduler (`scheduler:*`) actions, not Events (`events:*`)
- **DynamoDB**: Permissions added for table creation in `20_infra` layer, includes `DescribeTimeToLive` for reading TTL configuration
- **Route53 & ACM**: Permissions added for DNS and certificate management in `10_core` layer
- **Secrets Manager**: 
  - Scoped to `/practice/*` pattern for better least privilege
  - When `project_name` is provided, also allows `${project_name}-*` pattern
  - Requires `ManagedBy=Terraform` tag on secrets
  - Includes `GetResourcePolicy` for reading secret resource policies
- **KMS**: Key creation (`kms:CreateKey`) and deletion scheduling removed for security
- **IAM**: 
  - When `project_name` is provided, restricted to resources with matching `Project` tag
  - PassRole restricted to project-named roles (`${project_name}-*`) when `project_name` is provided
  - Includes `GetPolicyVersion` for reading IAM policy versions
- **Resource ARNs**: Scoped to specific account and region where possible
- **Policy Structure**: Simplified to only create plan and apply policies (removed redundant intermediate policies)

## References

- [AWS IAM Policy Documents](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [Terraform AWS Provider: IAM Policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
