# Policies Module

This module creates IAM policies for Terraform operations, including state access, resource creation, plan, and apply permissions.

## Resources Created

- `aws_iam_policy.terraform_state_access`: Policy for S3 state bucket and DynamoDB state locking
- `aws_iam_policy.terraform_resource_creation`: Policy for creating/updating/deleting Terraform resources
- `aws_iam_policy.terraform_plan`: Policy for Terraform plan operations (read-only + state access)
- `aws_iam_policy.terraform_apply`: Policy for Terraform apply operations (full access + state access)

## Usage

```hcl
module "terraform_policies" {
  source = "../modules/policies"

  policy_name_prefix = "github-actions-terraform-dev"
  state_bucket_arn   = "arn:aws:s3:::my-terraform-state-bucket"
  dynamodb_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-locks"
  account_id         = "123456789012"
  region             = "us-east-1"

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
| `policy_name_prefix` | `string` | Prefix for IAM policy names | `github-actions-terraform` | No |
| `state_bucket_arn` | `string` | ARN of the S3 bucket for Terraform state | - | Yes |
| `dynamodb_table_arn` | `string` | ARN of the DynamoDB table for state locking | - | Yes |
| `account_id` | `string` | AWS account ID | - | Yes |
| `region` | `string` | AWS region | - | Yes |
| `tags` | `map(string)` | Tags to apply to all policies | `{}` | No |

## Outputs

| Name | Description |
|------|-------------|
| `terraform_state_access_policy_arn` | ARN of the state access policy |
| `terraform_resource_creation_policy_arn` | ARN of the resource creation policy |
| `terraform_plan_policy_arn` | ARN of the plan policy |
| `terraform_apply_policy_arn` | ARN of the apply policy |
| `terraform_state_access_policy_name` | Name of the state access policy |
| `terraform_resource_creation_policy_name` | Name of the resource creation policy |
| `terraform_plan_policy_name` | Name of the plan policy |
| `terraform_apply_policy_name` | Name of the apply policy |

## Policy Details

### Terraform State Access Policy

Grants permissions for:
- S3: `GetObject`, `PutObject`, `ListBucket` on state bucket
- DynamoDB: `GetItem`, `PutItem`, `DeleteItem`, `DescribeTable` on state lock table

### Terraform Resource Creation Policy

Grants permissions for common Terraform resources:
- **Lambda**: Create, update, delete functions, aliases, permissions
- **API Gateway**: Full API Gateway permissions
- **SQS**: Create, update, delete queues
- **EventBridge**: Create, update, delete rules and targets
- **Secrets Manager**: Create, update, delete secrets
- **KMS**: Create, update, delete keys and aliases
- **CloudWatch Logs**: Create, update, delete log groups
- **IAM**: Create, update, delete roles and policies (limited, for service roles)
- **PassRole**: Pass roles to AWS services (Lambda, API Gateway, EventBridge)

### Terraform Plan Policy

Combines:
- State access permissions (full)
- Read-only resource permissions (Describe, List, Get operations)

### Terraform Apply Policy

Combines:
- State access permissions (full)
- Resource creation permissions (full)

## Security Considerations

- Policies follow least-privilege principle
- Resource ARNs are scoped to the specific account and region
- IAM permissions are limited to service role creation (not administrative IAM)
- PassRole permissions are restricted to specific services (Lambda, API Gateway, EventBridge)

## References

- [AWS IAM Policy Documents](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [Terraform AWS Provider: IAM Policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
