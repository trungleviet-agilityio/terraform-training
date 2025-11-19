# Worker Module

This module creates the worker Lambda function with SQS event source mapping for processing messages from an SQS queue.

## Purpose

Creates a Lambda function configured to receive and process messages from an SQS queue. Automatically creates the event source mapping that connects the SQS queue to the Lambda function.

## Resources

- Lambda function (via `lambda_sqs_worker` component)
- CloudWatch log group
- Lambda event source mapping (connects SQS queue to Lambda)
- Function configuration

## Usage

```hcl
module "worker" {
  source = "../modules/worker"

  function_name      = "${local.name_prefix}-worker"
  package            = module.runtime_code_modules.worker
  execution_role_arn = module.lambda_roles.worker_lambda_role_arn
  sqs_queue_arn      = var.sqs_queue_arn
  handler            = "worker.lambda_handler"
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
- `sqs_queue_arn` (required): ARN of the SQS queue
- `handler` (optional): Lambda handler function name. Default: `"worker.lambda_handler"`
- `runtime` (optional): Lambda runtime. Default: `"python3.13"`
- `memory_size` (optional): Memory size in MB. Default: `128`
- `timeout` (optional): Timeout in seconds. Default: `60`
- `log_retention_days` (optional): CloudWatch log retention in days. Default: `14`
- `enabled` (optional): Whether the event source mapping is enabled. Default: `true`
- `batch_size` (optional): Maximum number of records per batch. Default: `10`
- `maximum_batching_window_in_seconds` (optional): Maximum batching window in seconds. Default: `0`
- `environment_variables` (optional): Environment variables map. Default: `{}`
- `layers` (optional): Lambda layer ARNs list. Default: `[]`
- `tags` (optional): Tags to apply. Default: `{}`

## Outputs

- `function_arn`: ARN of the Worker Lambda function
- `function_name`: Name of the Worker Lambda function
- `event_source_mapping_id`: ID of the SQS event source mapping

## SQS Integration

This module automatically creates an event source mapping that connects the SQS queue to the Lambda function. The Lambda function will be invoked whenever messages are available in the queue.

**Important**: The SQS queue ARN must be provided from the `20_infra` layer:

```hcl
# In 30_app/environments/dev/main.tf
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket  = "tt-practice-tf-state-dev-<account-id>"
    key     = "infra/terraform.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

module "main" {
  source = "../../main"
  sqs_queue_arn = data.terraform_remote_state.infra.outputs.sqs_queue_arn
  # ... other config
}
```

## Handler Requirements

The Lambda function receives SQS events in batches:

```python
# src/lambda/worker/worker.py
import json

def lambda_handler(event, context):
    """Process SQS messages"""
    for record in event['Records']:
        # Parse SQS message
        message_body = json.loads(record['body'])
        print(f"Processing message: {message_body}")

        # Your message processing logic here

        # If processing fails, raise an exception
        # Lambda will retry the message automatically
        # After max retries, message goes to DLQ

    return {
        "statusCode": 200,
        "processed": len(event['Records'])
    }
```

## Batch Processing

The module supports batch processing with configurable batch size:
- `batch_size`: Number of messages to process in a single invocation (1-10)
- `maximum_batching_window_in_seconds`: Wait time to accumulate messages before invoking (0-300 seconds)

## Visibility Timeout

**Important**: The SQS queue's visibility timeout must be greater than the Lambda function timeout. AWS recommends:
- Visibility timeout >= 6 × Lambda timeout

Example:
- Lambda timeout: 60 seconds
- SQS visibility timeout: 360 seconds (6 minutes)

This is configured in the SQS queue module in the `20_infra` layer.

## Dead Letter Queue

Failed messages (after max retries) are automatically sent to the Dead Letter Queue (DLQ) configured in the SQS queue. Monitor the DLQ for failed messages.

## Notes

- This module wraps the `lambda_sqs_worker` component
- Package information comes from `runtime_code_modules` module
- Role comes from `lambda_roles` module (includes SQS permissions)
- SQS queue ARN comes from `20_infra` layer remote state
- Event source mapping is created automatically
- CloudWatch log group is automatically created
- Default timeout is 60 seconds (longer than API Lambda for message processing)
