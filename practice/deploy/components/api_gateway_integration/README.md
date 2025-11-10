# API Gateway Integration Component

This component creates API Gateway integration, route, and Lambda permission for connecting an API Gateway HTTP API to a Lambda function.

## Purpose

Creates the integration resources that connect an API Gateway HTTP API (created in `20_infra` layer) to a Lambda function (created in `30_app` layer).
## Resources

- `aws_apigatewayv2_integration`: Creates the integration between API Gateway and Lambda
- `aws_apigatewayv2_route`: Creates a default catch-all route that uses the integration
- `aws_lambda_permission`: Grants API Gateway permission to invoke the Lambda function

## Usage

```hcl
module "api_gateway_integration" {
  source = "../../../components/api_gateway_integration"

  api_gateway_id          = var.api_gateway_id
  api_gateway_execution_arn = var.api_gateway_execution_arn
  lambda_function_arn    = module.api_server.function_arn
  lambda_function_name   = module.api_server.function_name
}
```

## Variables

- `api_gateway_id` (required): API Gateway HTTP API ID (from `20_infra` layer outputs)
- `api_gateway_execution_arn` (required): API Gateway execution ARN (for Lambda permission source_arn)
- `lambda_function_arn` (required): ARN of the Lambda function to integrate
- `lambda_function_name` (required): Name of the Lambda function (for invoke permission)

## Outputs

- `integration_id`: ID of the API Gateway integration
- `route_id`: ID of the API Gateway route

## Architecture

This component is used in the `30_app` layer to integrate Lambda functions with API Gateway resources created in the `20_infra` layer. This maintains the proper deployment order:

1. `10_core` → Creates foundation
2. `20_infra` → Creates API Gateway HTTP API (without integration)
3. `30_app` → Creates Lambda functions AND integrations (using this component)

## Notes

- The integration uses `AWS_PROXY` integration type for Lambda proxy integration
- The route uses `$default` route key for catch-all routing
- Lambda permission is automatically created to allow API Gateway to invoke the function
- The API Gateway must exist before this component can be applied
