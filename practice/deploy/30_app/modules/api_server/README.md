# API Server Module

This module creates the API Lambda function using the FastAPI server component.

## Purpose

Creates a Lambda function configured for FastAPI applications, ready for integration with API Gateway. This module encapsulates the API server Lambda creation logic.

## Resources

- Lambda function (via `lambda_fastapi_server` component)
- CloudWatch log group
- Function configuration

## Usage

```hcl
module "api_server" {
  source = "../modules/api_server"

  function_name      = "${local.name_prefix}-api-server"
  package            = module.runtime_code_modules.api_server
  execution_role_arn = module.lambda_roles.api_lambda_role_arn
  handler            = "api_server.lambda_handler"
  runtime            = "python3.13"
  memory_size        = 128
  timeout            = 30
  tags               = local.common_tags
}
```

## Variables

- `function_name` (required): Name of the Lambda function
- `package` (required): Object containing `zip_path` and `zip_hash` from runtime_code_modules
- `execution_role_arn` (required): ARN of the IAM execution role
- `handler` (optional): Lambda handler function name. Default: `"api_server.lambda_handler"`
- `runtime` (optional): Lambda runtime. Default: `"python3.13"`
- `memory_size` (optional): Memory size in MB. Default: `128`
- `timeout` (optional): Timeout in seconds. Default: `30`
- `log_retention_days` (optional): CloudWatch log retention in days. Default: `14`
- `environment_variables` (optional): Environment variables map. Default: `{}`
- `layers` (optional): Lambda layer ARNs list. Default: `[]`
- `tags` (optional): Tags to apply. Default: `{}`

## Outputs

- `function_arn`: ARN of the API Lambda function
- `function_name`: Name of the API Lambda function
- `invoke_arn`: Invoke ARN for API Gateway integration

## Integration with API Gateway

The `invoke_arn` output is designed for API Gateway integration in the `20_infra` layer:

```hcl
# In 20_infra layer
module "api_gateway" {
  source = "../modules/api-gateway"
  lambda_function_arn  = data.terraform_remote_state.app.outputs.api_lambda_function_arn
  lambda_function_name = data.terraform_remote_state.app.outputs.api_lambda_function_name
  # ... other config
}
```

## Handler Requirements

The Lambda function expects a handler following this pattern:

```python
# src/lambda/api_server/api_server.py
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

## Notes

- This module wraps the `lambda_fastapi_server` component
- Package information comes from `runtime_code_modules` module
- Role comes from `lambda_roles` module
- Function ARN is output for use in `20_infra` API Gateway integration
- Default timeout is 30 seconds (adjust based on API response time requirements)
