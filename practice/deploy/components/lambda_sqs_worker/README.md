# Lambda SQS Worker Component

This component creates a Lambda function with SQS event source mapping for processing messages from an SQS queue.

## Purpose

Creates an AWS Lambda function configured to receive and process messages from an SQS queue. Automatically creates the event source mapping that connects the SQS queue to the Lambda function.

## Resources

- AWS Lambda function
- CloudWatch log group with retention policy
- Lambda event source mapping (connects SQS queue to Lambda)
- Function configuration (memory, timeout, environment variables)

## Usage

```hcl
module "sqs_worker" {
  source = "../../../components/lambda_sqs_worker"

  function_name      = "${var.project_name}-${var.environment}-worker"
  package_zip_path   = var.package.zip_path
  package_zip_hash   = var.package.zip_hash
  execution_role_arn = var.execution_role_arn
  sqs_queue_arn      = var.sqs_queue_arn
  handler            = "worker.lambda_handler"
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
- `sqs_queue_arn` (required): ARN of the SQS queue to trigger the Lambda function
- `handler` (optional): Lambda handler function name. Default: `"worker.lambda_handler"`
- `runtime` (optional): Lambda runtime. Default: `"python3.13"`
- `memory_size` (optional): Amount of memory in MB. Default: `128`
- `timeout` (optional): Timeout in seconds. Default: `60`
- `log_retention_days` (optional): CloudWatch log retention in days. Default: `14`
- `enabled` (optional): Whether the event source mapping is enabled. Default: `true`
- `batch_size` (optional): Maximum number of records to retrieve from SQS in one batch. Default: `10`
- `maximum_batching_window_in_seconds` (optional): Maximum amount of time to gather records before invoking the function. Default: `0` (no batching window)
- `environment_variables` (optional): Map of environment variables. Default: `{}`
- `layers` (optional): List of Lambda layer ARNs to attach. Default: `[]`
- `tags` (optional): Tags to apply to the Lambda function. Default: `{}`

## Outputs

- `function_arn`: ARN of the Lambda function
- `function_name`: Name of the Lambda function
- `event_source_mapping_id`: ID of the event source mapping

## SQS Integration

This component automatically creates an event source mapping that connects the SQS queue to the Lambda function. The Lambda function will be invoked whenever messages are available in the queue.

**Important**: The Lambda execution role must have permissions to:
- Receive messages from SQS
- Delete messages from SQS
- Get queue attributes

These permissions are typically added in the `lambda_roles` module.

## Handler Pattern

The Lambda function receives SQS events in batches:

```python
# worker.py
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

The component supports batch processing with configurable batch size:
- `batch_size`: Number of messages to process in a single invocation (1-10)
- `maximum_batching_window_in_seconds`: Wait time to accumulate messages before invoking (0-300 seconds)

Example with batching:
```hcl
module "sqs_worker" {
  # ... other config
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5  # Wait up to 5 seconds for batch
}
```

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

- The event source mapping is created automatically - no manual configuration needed
- Lambda processes messages in batches for efficiency
- Failed messages are automatically retried
- Messages that fail after max retries go to DLQ
- CloudWatch log group is automatically created
- The Lambda function depends on the SQS queue existing first
