# API Gateway HTTP API Module

This module creates an AWS API Gateway HTTP API with Lambda integration.

## Resources

- API Gateway HTTP API (with optional CORS configuration)
- API Gateway default stage
- API Gateway integration with Lambda function
- API Gateway routes (proxy integration)
- Lambda permission for API Gateway to invoke

## Usage

```hcl
module "api_gateway" {
  source = "../modules/api-gateway"

  project_name    = var.project_name
  environment     = var.environment
  lambda_function_arn = var.api_lambda_function_arn
  lambda_function_name = var.api_lambda_function_name
  
  tags = var.tags
}
```

## Variables

- `project_name`: Project name for resource naming
- `environment`: Environment name
- `lambda_function_arn`: ARN of the Lambda function to integrate
- `lambda_function_name`: Name of the Lambda function
- `api_name`: Optional custom name for the API (default: `${project_name}-${environment}-api`)
- `cors_configuration`: Optional CORS configuration (configured directly in API resource)
- `tags`: Tags to apply to resources

## Outputs

- `api_id`: API Gateway API ID
- `api_endpoint`: API Gateway HTTP endpoint URL
- `api_execution_arn`: API Gateway execution ARN
- `api_stage_id`: Default stage ID

## Notes

- Uses HTTP API (not REST API) for better performance and lower cost
- Default route: `$default` with proxy integration to Lambda
- Additional routes can be added as needed
- CORS is optional and configured directly in the `aws_apigatewayv2_api` resource using a `dynamic` block
