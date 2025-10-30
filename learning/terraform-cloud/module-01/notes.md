# Module 01 – Importing AWS Lambda into Terraform

## Learning Objectives
- Understand what `terraform import` does and when to use it
- Identify all Lambda‑adjacent AWS resources to import (IAM Role, policy attachments, CloudWatch Log Group)
- Refine imported resources into clean, accurate Terraform configuration
- Use config generation to scaffold HCL and then harden it
- Clean up safely with full lifecycle (create → update → destroy)

## Session Notes

### 1) What gets created with a Lambda?
- Lambda function (code + runtime + handler)
- IAM Role (execution role) and policy attachments (e.g., `AWSLambdaBasicExecutionRole`)
- CloudWatch Log Group `/aws/lambda/<function-name>` (created on first invocation)
- Optional: VPC ENIs/security groups if VPC‑enabled; resource‑based permissions if triggered by API Gateway/S3/etc.

### 2) Why import instead of recreate?
- Preserve uptime and dependencies; avoid data/config loss
- Eliminate drift by aligning real resources with Terraform state
- Bring manual assets into versioned, reviewable IaC

### 3) Import model (explicit and per‑resource)
- Import adds an existing object to state; it does not write HCL
- Each dependency must be imported individually (Lambda, IAM Role, role policy attachments, Log Group, etc.)
- Typical order:
  1. IAM Role (+ assume role policy)
  2. IAM role policy attachments
  3. Lambda function
  4. CloudWatch Log Group

### 4) Minimal workflow
1. Create placeholder resources in HCL (just enough to have addresses)
2. Import each resource by address and ID
3. Run `terraform plan` and refine HCL to match real attributes until the plan is clean

Example addresses and commands:
```bash
# Lambda (by name or ARN depending on provider docs)
terraform import aws_lambda_function.fn my-lambda-function

# Execution role (by role ARN)
terraform import aws_iam_role.lambda_exec arn:aws:iam::123456789012:role/my-lambda-execution-role

# Basic execution policy attachment (attachment ID format varies; prefer importing each attachment)
terraform import aws_iam_role_policy_attachment.basic \
  arn:aws:iam::123456789012:role/my-lambda-execution-role/AWSLambdaBasicExecutionRole

# CloudWatch Log Group (by name)
terraform import aws_cloudwatch_log_group.lambda_logs /aws/lambda/my-lambda-function
```

### 5) Configuration scaffolding and hardening
- Generate starter HCL for large imports (Terraform ≥ 1.5):
  - `terraform plan -generate-config-out=generated.tf`
- Treat generated code as a starting point, then:
  - Replace computed values with explicit configuration where appropriate
  - Externalize code packages (ZIP) via `archive_file` or CI artifact
  - Model dependencies explicitly (e.g., `role = aws_iam_role.lambda_exec.arn`)
  - Add `tags`, `retention_in_days` for logs, and other org standards

### 6) Common pitfalls
- Expecting import to generate HCL (it only updates state)
- Forgetting to import dependencies (role, attachments, log group)
- Mis‑matching names/handlers/runtimes → Terraform plans replacement
- Leaving the CloudWatch Log Group unmanaged → drift on retention

### 7) Cleanup and costs
- Always destroy lab resources when done: `terraform destroy`
- Remove unused roles, policies, and log groups to avoid surprises

## Quick Commands Reference
- Show state entries: `terraform state list`
- Show a single object: `terraform state show <addr>`
- Import: `terraform import <addr> <id>`
- Generate starter config (≥ 1.5): `terraform plan -generate-config-out=generated.tf`
- Apply changes: `terraform apply`
- Destroy resources: `terraform destroy`

## Exercise References
- `exercises/terraform-cloud/module-01/project-03-import-lambda/` – Practice importing Lambda, IAM Role, and CloudWatch Log Group
- `exercises/terraform-cloud/module-01/solution/` – A consolidated working example to compare against

## Key Takeaways
- Import brings existing resources under Terraform without recreation
- Each related resource must be imported explicitly
- Generated config is a scaffold—refine it to match standards
- Finish the lifecycle with cleanup to control cost and drift
