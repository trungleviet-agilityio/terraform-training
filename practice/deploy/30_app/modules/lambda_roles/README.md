# Lambda Roles Module

This module creates IAM execution roles for all Lambda functions.

## Purpose

Creates IAM roles with appropriate permissions for Lambda function execution. Each Lambda function type (API, cron, worker) gets its own dedicated role with least-privilege permissions.

## Resources

- Three IAM roles (one for each Lambda function type)
- AWS managed policy attachments (basic Lambda execution)
- Custom IAM policy for SQS worker (SQS receive/delete permissions)

## Usage

```hcl
module "lambda_roles" {
  source = "../modules/lambda_roles"

  project_name  = var.project_name
  environment   = var.environment
  sqs_queue_arn = var.sqs_queue_arn
  tags          = local.common_tags
}
```

## Variables

- `project_name` (required): Project name for resource naming
- `environment` (required): Environment name (dev, stage, prod)
- `sqs_queue_arn` (required): ARN of the SQS queue (for worker Lambda permissions)
- `tags` (optional): Tags to apply to IAM roles. Default: `{}`

## Outputs

- `api_lambda_role_arn`: ARN of the IAM role for API Lambda function
- `cron_lambda_role_arn`: ARN of the IAM role for Cron Lambda function
- `worker_lambda_role_arn`: ARN of the IAM role for Worker Lambda function

## Role Details

### API Lambda Role
- **Name**: `{project_name}-{environment}-api-lambda-role`
- **Permissions**: 
  - Basic Lambda execution (CloudWatch Logs)
  - Can be extended with additional policies for API Gateway, DynamoDB, etc.

### Cron Lambda Role
- **Name**: `{project_name}-{environment}-cron-lambda-role`
- **Permissions**:
  - Basic Lambda execution (CloudWatch Logs)
  - Can be extended with additional policies for SQS send, DynamoDB, etc.

### Worker Lambda Role
- **Name**: `{project_name}-{environment}-worker-lambda-role`
- **Permissions**:
  - Basic Lambda execution (CloudWatch Logs)
  - SQS permissions: `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes`
  - Access restricted to the specified SQS queue ARN

## Extended Permissions

To add additional permissions to a role, use `aws_iam_role_policy` resources:

```hcl
# Example: Add DynamoDB permissions to API role
resource "aws_iam_role_policy" "api_dynamodb" {
  name = "${var.project_name}-${var.environment}-api-dynamodb-policy"
  role = module.lambda_roles.api_lambda_role_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      Resource = "arn:aws:dynamodb:${var.region}:*:table/*"
    }]
  })
}
```

## Notes

- All roles use the standard Lambda execution trust policy
- Roles follow naming convention: `{project}-{env}-{type}-lambda-role`
- Worker role has SQS-specific permissions for the queue
- Additional permissions should be added via separate policy resources
- Roles are tagged with standard project tags
