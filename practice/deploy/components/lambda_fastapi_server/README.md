# Lambda FastAPI Server Component

This component creates a Lambda function configured for FastAPI applications.

## Purpose

Creates an AWS Lambda function optimized for FastAPI serverless applications. Includes CloudWatch log group, proper handler configuration, and supports Lambda layers for dependencies.

## Resources

- AWS Lambda function
- CloudWatch log group with retention policy
- Function configuration (memory, timeout, environment variables)

## Usage

```hcl
module "fastapi_lambda" {
  source = "../../../components/lambda_fastapi_server"

  function_name      = "${var.project_name}-${var.environment}-api-server"
  package_zip_path   = var.package.zip_path
  package_zip_hash   = var.package.zip_hash
  execution_role_arn = var.execution_role_arn
  handler            = "api_server.lambda_handler"
  runtime            = "python3.13"
  memory_size        = 128
  timeout            = 30
  
  tags = local.common_tags
}
```

## Variables

- `function_name` (required): Name of the Lambda function
- `package_zip_path` (required): Path to the zip file containing Lambda code
- `package_zip_hash` (required): Base64-encoded SHA256 hash of the zip file
- `execution_role_arn` (required): ARN of the IAM execution role for the Lambda function
- `handler` (optional): Lambda handler function name. Default: `"api_server.lambda_handler"`
- `runtime` (optional): Lambda runtime. Default: `"python3.13"`
- `memory_size` (optional): Amount of memory in MB. Default: `128`
- `timeout` (optional): Timeout in seconds. Default: `30`
- `log_retention_days` (optional): CloudWatch log retention in days. Default: `14`
- `environment_variables` (optional): Map of environment variables. Default: `{}`
- `layers` (optional): List of Lambda layer ARNs to attach. Default: `[]`
- `tags` (optional): Tags to apply to the Lambda function. Default: `{}`

## Outputs

- `function_arn`: ARN of the Lambda function
- `function_name`: Name of the Lambda function
- `invoke_arn`: ARN to be used for invoking Lambda Function from API Gateway

## FastAPI Handler Pattern

The Lambda function expects a handler function following this pattern:

```python
# api_server.py
from mangum import Mangum
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello World"}

def lambda_handler(event, context):
    handler = Mangum(app)
    return handler(event, context)
```

## Integration with API Gateway

The `invoke_arn` output is designed for API Gateway integration:

```hcl
resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.fastapi_lambda.invoke_arn
}
```

## Notes

- CloudWatch log group is automatically created with the name `/aws/lambda/{function_name}`
- The function depends on the log group being created first
- For production, consider using Lambda layers for dependencies to reduce package size
- Memory and timeout should be adjusted based on workload requirements

