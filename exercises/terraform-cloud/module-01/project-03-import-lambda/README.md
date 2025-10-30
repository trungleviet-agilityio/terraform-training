# Importing Lambda Resources into Terraform

This project teaches how to adopt an existing, manually created AWS Lambda into Terraform. You will import the Lambda, its execution role, and the CloudWatch Log Group, then refine configuration and clean up.

## Learning Objectives
- Use `terraform import` to bring existing resources under Terraform management
- Import dependent resources explicitly (IAM role, policy attachments, CloudWatch Log Group)
- Generate starter configuration and refine it to your standards
- Destroy lab resources to control cost and avoid drift

## Prerequisites
- AWS account and credentials configured in your environment
- Terraform ≥ 1.5 (for config generation command)
- Basic understanding of IAM roles and CloudWatch Logs

## What gets created with a Lambda
- Lambda function (runtime, handler, code package)
- IAM Role (execution role) + policy attachments (e.g., `AWSLambdaBasicExecutionRole`)
- CloudWatch Log Group `/aws/lambda/<function-name>` (created on first invocation)

## Steps
1) Create a Lambda manually (Console)
- Use the "hello-world" blueprint
- Choose "Create a new role with basic permissions" for the execution role

2) Create minimal placeholders in Terraform
```hcl
resource "aws_lambda_function" "fn" {
  function_name = "my-lambda-function"
}

resource "aws_iam_role" "lambda_exec" {
  name = "my-lambda-execution-role"
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name = "/aws/lambda/my-lambda-function"
}
```

3) Import resources into state
```bash
# Lambda (by name or ARN depending on docs)
terraform import aws_lambda_function.fn my-lambda-function

# Execution role (by role ARN)
terraform import aws_iam_role.lambda_exec arn:aws:iam::123456789012:role/my-lambda-execution-role

# Basic execution policy attachment (import each attachment you find)
terraform import aws_iam_role_policy_attachment.basic \
  arn:aws:iam::123456789012:role/my-lambda-execution-role/AWSLambdaBasicExecutionRole

# CloudWatch Log Group (by name)
terraform import aws_cloudwatch_log_group.lambda_logs /aws/lambda/my-lambda-function
```

4) Generate and refine configuration (optional but recommended)
- Generate starter HCL (Terraform ≥ 1.5):
  - `terraform plan -generate-config-out=generated.tf`
- Refine the code:
  - Model `role = aws_iam_role.lambda_exec.arn`
  - Externalize code ZIP via `archive_file` or CI artifact
  - Add `retention_in_days` for logs and `tags` across resources
  - Ensure handler/runtime/architectures match the real Lambda

5) Verify
- `terraform plan` should show no unexpected replacements/changes

6) Cleanup
- Destroy when finished to avoid costs:
  - `terraform destroy`

## Tips
- Import is per‑resource and does not write HCL; create placeholders first
- Use AWS Console to find exact Role ARN, function name, and log group name
- Keep retention and tagging consistent with your org’s standards

## Expected Outcome
- All Lambda artifacts (function, role, log group, key attachments) are tracked by Terraform
- Plans are clean and reproducible; environment can be fully created and destroyed by Terraform

## See Also
- Notes: `learning/terraform-cloud/module-01/notes.md`
- Solution: `exercises/terraform-cloud/module-01/solution/`
