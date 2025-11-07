# API Gateway HTTP API Module

This module creates an AWS API Gateway HTTP API with Lambda integration and optional custom domain support.

## Resources

- API Gateway HTTP API (with optional CORS configuration)
- API Gateway default stage
- API Gateway integration with Lambda function
- API Gateway routes (proxy integration)
- Lambda permission for API Gateway to invoke
- Custom domain name (optional)
- API mapping to custom domain (optional)
- Route53 A record for custom domain (optional)

## Usage

### Basic Usage (Default Endpoint)

```hcl
module "api_gateway" {
  source = "../modules/api-gateway"

  project_name         = var.project_name
  environment          = var.environment
  lambda_function_arn = var.api_lambda_function_arn
  lambda_function_name = var.api_lambda_function_name

  tags = var.tags
}
```

### With Custom Domain

```hcl
module "api_gateway" {
  source = "../modules/api-gateway"

  project_name         = var.project_name
  environment          = var.environment
  lambda_function_arn = var.api_lambda_function_arn
  lambda_function_name = var.api_lambda_function_name

  custom_domain_config = {
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
    domain_name     = "api.dev.example.com"
    hosted_zone_id  = "Z1234567890ABC"  # Optional: Creates Route53 A record if provided
  }
  
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
- `custom_domain_config`: Optional custom domain configuration
  - `certificate_arn`: ACM certificate ARN (must be in us-east-1 for API Gateway)
  - `domain_name`: Custom domain name (e.g., api.dev.example.com)
  - `hosted_zone_id`: Route53 hosted zone ID (optional, creates A record if provided)
- `tags`: Tags to apply to resources

## Outputs

- `api_id`: API Gateway API ID
- `api_endpoint`: API Gateway HTTP endpoint URL (default endpoint)
- `api_execution_arn`: API Gateway execution ARN
- `api_stage_id`: Default stage ID
- `api_name`: API Gateway name
- `api_zone_id`: API Gateway hosted zone ID (for Route53 alias records)
- `custom_domain_name`: Custom domain name (null if not configured)
- `custom_domain_arn`: ARN of custom domain (null if not configured)
- `custom_domain_target`: Target domain for Route53 alias (null if not configured)
- `custom_domain_hosted_zone_id`: Hosted zone ID for Route53 alias (null if not configured)

## Custom Domain Setup

### Prerequisites

1. **ACM Certificate**: Must be created in `us-east-1` region (required for API Gateway)
2. **Route53 Hosted Zone**: For DNS management (optional, but recommended)
3. **Domain Name**: Choose a subdomain (e.g., `api.dev.example.com`)

### Step-by-Step Setup

1. **Create Certificate in us-east-1** (in `10_core` layer):
   ```hcl
   provider "aws" {
     alias  = "us_east_1"
     region = "us-east-1"
   }

   module "dns" {
     source = "../modules/dns"

     certificate_provider = aws.us_east_1
     # ... other variables
   }
   ```

2. **Get Certificate ARN** from `10_core` outputs (via remote state)

3. **Configure Custom Domain** in `20_infra` layer:
   ```hcl
   custom_domain_config = {
     certificate_arn = data.terraform_remote_state.core.outputs.dns_certificate_arn
     domain_name     = "api.${data.terraform_remote_state.core.outputs.dns_hosted_zone_name}"
     hosted_zone_id  = data.terraform_remote_state.core.outputs.dns_hosted_zone_id
   }
   ```

4. **Access API**: After deployment, API will be accessible at `https://api.dev.example.com`

## Notes

- Uses HTTP API (not REST API) for better performance and lower cost
- Default route: `$default` with proxy integration to Lambda
- Custom domain is completely optional - API works with default endpoint
- Certificate MUST be in us-east-1 for API Gateway custom domains
- Route53 A record is created automatically if `hosted_zone_id` is provided
- TLS 1.2 security policy is enforced for custom domains
- REGIONAL endpoint type is used (required for API Gateway)
- CORS is optional and configured directly in the `aws_apigatewayv2_api` resource using a `dynamic` block

## Practice vs Production

**Practice Mode** (No Custom Domain):
- Use default API Gateway endpoint
- No certificate or DNS setup required
- Works immediately after deployment
- Example: `https://abc123.execute-api.ap-southeast-1.amazonaws.com`

**Production Mode** (With Custom Domain):
- Configure custom domain with certificate
- Professional domain name
- Better for public APIs
- Example: `https://api.dev.example.com`
