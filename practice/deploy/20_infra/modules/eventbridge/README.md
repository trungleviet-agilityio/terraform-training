# EventBridge Schedule Module

This module creates an EventBridge schedule (cron job) to trigger Lambda functions on a schedule.

## Resources

- EventBridge Schedule Rule
- IAM role for EventBridge to invoke Lambda
- IAM policy allowing Lambda invocation

## Usage

```hcl
module "eventbridge_schedule" {
  source = "../modules/eventbridge"

  project_name        = var.project_name
  environment         = var.environment
  schedule_name       = "cron-producer"
  schedule_expression = "cron(0 12 * * ? *)"  # Daily at 12:00 PM UTC
  lambda_function_arn = var.producer_lambda_arn
  lambda_function_name = var.producer_lambda_name
  
  tags = var.tags
}
```

## Variables

- `project_name`: Project name for resource naming
- `environment`: Environment name
- `schedule_name`: Name of the schedule (default: "cron-producer")
- `schedule_expression`: Cron or rate expression (default: "cron(0 12 * * ? *)")
- `lambda_function_arn`: ARN of the Lambda function to invoke
- `lambda_function_name`: Name of the Lambda function (for IAM permission)
- `enabled`: Whether the schedule is enabled (default: true)
- `description`: Description of the schedule
- `input`: JSON input to pass to Lambda (default: "{}")
- `tags`: Tags to apply to resources

## Outputs

- `schedule_arn`: ARN of the EventBridge schedule
- `schedule_name`: Name of the schedule
- `schedule_state`: State (ENABLED or DISABLED)
- `iam_role_arn`: ARN of the IAM role
- `iam_role_name`: Name of the IAM role

## Schedule Expressions

### Cron Format
```
cron(minute hour day-of-month month day-of-week year)
```

**Examples**:
- `cron(0 12 * * ? *)` - Daily at 12:00 PM UTC
- `cron(0 0 1 * ? *)` - First day of every month at midnight
- `cron(0 9 ? * MON-FRI *)` - Weekdays at 9:00 AM UTC
- `cron(0/15 * * * ? *)` - Every 15 minutes

### Rate Format
```
rate(value unit)
```

**Examples**:
- `rate(5 minutes)` - Every 5 minutes
- `rate(1 hour)` - Every hour
- `rate(1 day)` - Every day

## Common Cron Patterns

| Pattern | Description |
|---------|-------------|
| `cron(0 12 * * ? *)` | Daily at 12:00 PM UTC |
| `cron(0 0 * * ? *)` | Daily at midnight UTC |
| `cron(0 9 ? * MON-FRI *)` | Weekdays at 9:00 AM UTC |
| `cron(0 0 1 * ? *)` | First day of month at midnight |
| `cron(0/15 * * * ? *)` | Every 15 minutes |
| `cron(0 0 1 1 ? *)` | January 1st at midnight |

## Lambda Input

You can pass JSON input to the Lambda function:

```hcl
input = jsonencode({
  action = "process"
  type   = "daily"
})
```

Or use a string:

```hcl
input = "{\"action\": \"process\", \"type\": \"daily\"}"
```

## IAM Permissions

The module automatically creates:
- IAM role for EventBridge (assumes scheduler.amazonaws.com)
- IAM policy allowing `lambda:InvokeFunction` on the target Lambda

**Note**: The Lambda function also needs a resource-based policy allowing EventBridge to invoke it. This is typically handled by the Lambda permission resource in the Lambda module.

## Example: Daily Cron Job

```hcl
module "daily_cron" {
  source = "../modules/eventbridge"

  project_name        = var.project_name
  environment         = var.environment
  schedule_name       = "daily-task"
  schedule_expression = "cron(0 2 * * ? *)"  # Daily at 2:00 AM UTC
  lambda_function_arn = module.producer_lambda.function_arn
  lambda_function_name = module.producer_lambda.function_name
  description         = "Daily cron job to process tasks"
  input              = jsonencode({
    task_type = "daily"
    priority  = "normal"
  })

  tags = var.tags
}
```

## Example: Every 5 Minutes

```hcl
module "frequent_cron" {
  source = "../modules/eventbridge"

  project_name        = var.project_name
  environment         = var.environment
  schedule_name       = "frequent-task"
  schedule_expression = "rate(5 minutes)"
  lambda_function_arn = module.producer_lambda.function_arn
  lambda_function_name = module.producer_lambda.function_name
  enabled            = true

  tags = var.tags
}
```

## Notes

- **Timezone**: Cron expressions use UTC by default
- **Flexible Time Window**: Currently set to "OFF" (exact schedule). Can be configured for more flexibility
- **State**: Can be enabled/disabled without deleting the schedule
- **Lambda Permissions**: Ensure Lambda has permission for EventBridge to invoke it (handled by Lambda module)

## Troubleshooting

### Schedule Not Triggering
1. Check `schedule_state` output - should be "ENABLED"
2. Verify Lambda function ARN is correct
3. Check Lambda function has permission for EventBridge
4. Review CloudWatch Logs for EventBridge execution logs

### Invalid Schedule Expression
- Verify cron syntax: `cron(minute hour day month day-of-week year)`
- Use `?` for day-of-month OR day-of-week (not both)
- Ensure timezone is UTC
