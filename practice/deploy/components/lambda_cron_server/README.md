# Lambda Cron Server Component

This component creates a Lambda function for scheduled tasks triggered by EventBridge.

## Purpose

Creates an AWS Lambda function designed to be triggered by EventBridge schedules (cron jobs). Includes CloudWatch logging and supports standard Lambda configuration options.

## Resources

- AWS Lambda function
- CloudWatch log group with retention policy
- Function configuration (memory, timeout, environment variables)

## Usage

```hcl
module "cron_lambda" {
  source = "../../../components/lambda_cron_server"

  function_name      = "${var.project_name}-${var.environment}-cron-server"
  package_zip_path   = var.package.zip_path
  package_zip_hash   = var.package.zip_hash
  execution_role_arn = var.execution_role_arn
  handler            = "cron_server.lambda_handler"
  runtime            = "python3.13"
  memory_size        = 128
  timeout            = 60
  
  tags = local.common_tags
}
```

## Variables

- `function_name` (required): Name of the Lambda function
- `package_zip_path` (required): Path to the zip file containing Lambda code
- `package_zip_hash` (required): Base64-encoded SHA256 hash of the zip file
- `execution_role_arn` (required): ARN of the IAM execution role for the Lambda function
- `handler` (optional): Lambda handler function name. Default: `"cron_server.lambda_handler"`
- `runtime` (optional): Lambda runtime. Default: `"python3.13"`
- `memory_size` (optional): Amount of memory in MB. Default: `128`
- `timeout` (optional): Timeout in seconds. Default: `60` (longer than API Lambda for batch processing)
- `log_retention_days` (optional): CloudWatch log retention in days. Default: `14`
- `environment_variables` (optional): Map of environment variables. Default: `{}`
- `layers` (optional): List of Lambda layer ARNs to attach. Default: `[]`
- `tags` (optional): Tags to apply to the Lambda function. Default: `{}`

## Outputs

- `function_arn`: ARN of the Lambda function
- `function_name`: Name of the Lambda function

## EventBridge Integration

This Lambda function is designed to be triggered by EventBridge schedules. Create the EventBridge schedule in the `20_infra` layer:

```hcl
resource "aws_scheduler_schedule" "cron" {
  name        = "my-schedule"
  schedule_expression = "cron(0 12 * * ? *)"  # Daily at 12:00 PM UTC

  target {
    arn      = module.cron_lambda.function_arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}
```

## Handler Pattern

The Lambda function expects a handler function:

```python
# cron_server.py
import json

def lambda_handler(event, context):
    """Process scheduled event from EventBridge"""
    print(f"Received event: {json.dumps(event)}")

    # Your scheduled task logic here
    # For example: enqueue messages to SQS, process data, etc.

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Cron job completed"})
    }
```

## Notes

- Default timeout is 60 seconds (longer than API Lambda) to support batch operations
- CloudWatch log group is automatically created
- EventBridge schedule creation happens in the `20_infra` layer
- Consider using longer timeouts for data processing tasks
- Monitor CloudWatch logs for cron execution status
