# Cron Server Module

This module creates the cron Lambda function for scheduled tasks triggered by EventBridge.

## Purpose

Creates a Lambda function configured for scheduled execution via EventBridge schedules. This module encapsulates the cron Lambda creation logic.

## Resources

- Lambda function (via `lambda_cron_server` component)
- CloudWatch log group
- Function configuration

## Usage

```hcl
module "cron_server" {
  source = "../modules/cron_server"

  function_name      = "${local.name_prefix}-cron-server"
  package            = module.runtime_code_modules.cron_server
  execution_role_arn = module.lambda_roles.cron_lambda_role_arn
  handler            = "cron_server.lambda_handler"
  runtime            = "python3.13"
  memory_size        = 128
  timeout            = 60
  tags               = local.common_tags
}
```

## Variables

- `function_name` (required): Name of the Lambda function
- `package` (required): Object containing `zip_path` and `zip_hash` from runtime_code_modules
- `execution_role_arn` (required): ARN of the IAM execution role
- `handler` (optional): Lambda handler function name. Default: `"cron_server.lambda_handler"`
- `runtime` (optional): Lambda runtime. Default: `"python3.13"`
- `memory_size` (optional): Memory size in MB. Default: `128`
- `timeout` (optional): Timeout in seconds. Default: `60`
- `log_retention_days` (optional): CloudWatch log retention in days. Default: `14`
- `environment_variables` (optional): Environment variables map. Default: `{}`
- `layers` (optional): Lambda layer ARNs list. Default: `[]`
- `tags` (optional): Tags to apply. Default: `{}`

## Outputs

- `function_arn`: ARN of the Cron Lambda function
- `function_name`: Name of the Cron Lambda function

## Integration with EventBridge

EventBridge schedule creation happens **within the 30_app layer** using the `eventbridge_target` component. This ensures the Lambda function exists before creating the schedule and avoids circular dependencies.

The schedule is typically created in the module that uses this `cron_server` module, passing the schedule expression from configuration.

## Handler Requirements

The Lambda function expects a handler following this pattern:

```python
# src/lambda/cron_server/cron_server.py
import json

def lambda_handler(event, context):
    """Process scheduled event from EventBridge"""
    print(f"Received event: {json.dumps(event)}")

    # Your scheduled task logic here
    # Example: Enqueue messages to SQS, process data, etc.

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Cron job completed"})
    }
```

## Notes

- This module wraps the `lambda_cron_server` component
- Package information comes from `runtime_code_modules` module
- Role comes from `20_infra` layer via remote state (lambda_cron_role_arn)
- Default timeout is 60 seconds (longer than API Lambda for batch operations)
- EventBridge schedule creation happens in the `30_app` layer using the `eventbridge_target` component
