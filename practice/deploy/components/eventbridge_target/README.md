# EventBridge Target Component

This component creates an EventBridge schedule with a Lambda target and the necessary IAM role for EventBridge to invoke the Lambda function.

## Purpose

Creates an EventBridge schedule with a Lambda target.

## Resources

- `aws_iam_role`: IAM role for EventBridge to assume when invoking Lambda
- `aws_iam_role_policy`: Policy allowing EventBridge to invoke the Lambda function
- `aws_scheduler_schedule`: Creates the schedule with Lambda target

## Usage

```hcl
module "eventbridge_target" {
  source = "../../../components/eventbridge_target"

  project_name         = var.project_name
  environment          = var.environment
  schedule_name        = "${var.project_name}-${var.environment}-cron-producer-schedule"
  schedule_expression  = var.eventbridge_schedule_expression
  lambda_function_arn  = module.cron_server.function_arn
  lambda_function_name = module.cron_server.function_name

  tags = local.common_tags
}
```

## Variables

- `project_name` (required): Project name for resource naming
- `environment` (required): Environment name (e.g., dev, stage, prod)
- `schedule_name` (required): Name of the EventBridge schedule
- `schedule_expression` (required): Schedule expression (cron or rate). Example: `cron(0 12 * * ? *)` or `rate(5 minutes)`
- `lambda_function_arn` (required): ARN of the Lambda function to invoke
- `lambda_function_name` (required): Name of the Lambda function (for IAM permission)
- `enabled` (optional): Whether the schedule is enabled. Default: `true`
- `input` (optional): JSON input to pass to the Lambda function. Default: `"{}"`
- `tags` (optional): Tags to apply to all resources. Default: `{}`

## Outputs

- `schedule_arn`: ARN of the EventBridge schedule
- `iam_role_arn`: ARN of the IAM role used by EventBridge

## Architecture

This component is used in the `30_app` layer to create EventBridge schedules with Lambda targets. This maintains the proper deployment order:

1. `10_core` → Creates foundation
2. `20_infra` → Creates platform services (SQS, DynamoDB, API Gateway)
3. `30_app` → Creates Lambda functions AND EventBridge schedules (using this component)

## Notes

- The schedule is created with the Lambda target included
- IAM role is automatically created for EventBridge to invoke the Lambda function
- The Lambda function must exist before this component can be applied
- Schedule expression follows AWS EventBridge Scheduler format (cron or rate)
