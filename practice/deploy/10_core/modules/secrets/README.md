# AWS Secrets Manager Secret Module

This module creates AWS Secrets Manager secrets with standardized naming conventions for use in Lambda functions and other AWS services.

## Resources Created

- **AWS Secrets Manager Secret**: Container for secret metadata
  - Uses naming convention: `/practice/<environment>/<layer>/<secret-name>` (when layer is provided) or `/practice/<environment>/<secret-name>` (when layer is null)
  - Optional KMS encryption
  - Tags applied

- **Secret Version**: Optional initial secret value
  - Only created if `secret_string` is provided
  - Can be set later via AWS Console or CI/CD

## Usage

```hcl
# Layer-specific secret (organized by layer, matches folder structure)
module "terraform_vars" {
  source = "../modules/secrets"

  secret_name  = "terraform-vars"
  layer        = "10_core"  # Optional: organize by layer (10_core, 20_infra, 30_app)
  description  = "Terraform variables for 10_core layer"
  environment  = "dev"
  secret_string = jsonencode({
    aws_region = "ap-southeast-1"
    project_name = "tt-practice"
  })
  
  tags = {
    Environment = "dev"
    Project     = "tt-practice"
    ManagedBy   = "Terraform"
  }
}

# Environment-level secret (no layer, for shared secrets)
module "backend_bucket_secret" {
  source = "../modules/secrets"

  secret_name  = "backend-bucket"
  # layer = null  # Optional: omit for environment-level secrets
  description  = "Terraform state backend bucket name"
  environment  = "dev"
  secret_string = jsonencode({
    bucket = "my-state-bucket"
  })
  
  tags = local.common_tags
}
```

## Outputs

- `secret_arn`: ARN of the secret (for Lambda environment variables)
- `secret_name`: Full name of the secret (`/practice/<environment>/<layer>/<secret-name>` or `/practice/<environment>/<secret-name>`)
- `secret_id`: ID of the secret resource
- `secret_version_id`: Version ID of the secret version (if created)

## Naming Convention

- Format: `/practice/<environment>/<layer>/<secret-name>` (when layer is provided)
- Format: `/practice/<environment>/<secret-name>` (when layer is null, for environment-level secrets)
- Examples:
  - `/practice/dev/10_core/terraform-vars` (layer-specific)
  - `/practice/dev/20_infra/terraform-vars` (layer-specific)
  - `/practice/dev/backend-bucket` (environment-level, no layer)
  - `/practice/prod/30_app/terraform-vars` (layer-specific)

Uses forward slash prefix for AWS Secrets Manager hierarchical naming convention, matching the folder structure (`practice/deploy/{layer}/environments/{env}/`).

**Note:** AWS Secrets Manager does not create actual folders. The forward slashes are part of the secret name for logical organization. The console displays secrets in a flat list, but the hierarchical naming helps with:
- **Filtering/Searching**: Use the search bar with prefix filters like `/practice/dev/` to find environment-specific secrets
- **IAM Policies**: Organize access control by path patterns (e.g., `/practice/dev/*`)
- **Logical Grouping**: Clear naming convention that matches your infrastructure structure

**Viewing Secrets in AWS Console:**
- All secrets appear in a flat list view
- Use the search/filter bar with prefix: `/practice/dev/` to filter dev environment secrets
- Use `/practice/dev/20_infra/` to filter specific layer secrets
- The hierarchical naming makes it easy to identify and manage secrets by environment and layer

## Security Best Practices

1. **Never store secret values in Terraform variables**
   - Pass `secret_string = null` and set values via AWS Console or CI/CD
   - Use GitHub Secrets or CI/CD pipelines to inject secret values

2. **Use KMS encryption**
   - Provide `kms_key_id` for additional encryption control
   - If not provided, AWS Secrets Manager uses the default KMS key

3. **Environment isolation**
   - Each environment (dev/stage/prod) has separate secrets
   - Secrets are environment-specific by design

4. **IAM permissions**
   - Only grant `secretsmanager:GetSecretValue` to services that need it
   - Reference secret ARNs (not values) in other layers

## Lambda Integration

To use secrets in Lambda functions:

1. **Output secret ARN** from 10_core layer:
```hcl
output "api_key_secret_arn" {
  value = module.api_key_secret.secret_arn
}
```

2. **Pass ARN as environment variable** in Lambda (30_app layer):
```hcl
environment {
  variables = {
    API_KEY_SECRET_ARN = module.core.api_key_secret_arn
  }
}
```

3. **Grant IAM permissions** (20_infra layer):
```hcl
resource "aws_iam_role_policy" "lambda_secrets" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [module.core.api_key_secret_arn]
    }]
  })
}
```

4. **Read secret in Lambda code**:
```python
import boto3
import json
import os

def lambda_handler(event, context):
    client = boto3.client('secretsmanager')
    secret_arn = os.environ['API_KEY_SECRET_ARN']
    
    response = client.get_secret_value(SecretId=secret_arn)
    api_key = json.loads(response['SecretString'])
    
    # Use api_key safely
    return {"statusCode": 200}
```

## Setting Secret Values

### Via AWS Console
1. Navigate to AWS Secrets Manager
2. Select the secret
3. Click "Retrieve secret value" → "Edit"
4. Set the secret value

### Via AWS CLI
```bash
aws secretsmanager put-secret-value \
  --secret-id /practice/dev/api-key \
  --secret-string "your-secret-value"
```

### Via CI/CD
- Use GitHub Secrets to store secret values
- Use AWS CLI or SDK in CI/CD pipeline to set secret values
- Never commit secret values to version control

## Notes

- Secret values are sensitive and should never be committed to version control
- The module creates the secret container; values should be set separately
- If `secret_string` is provided, an initial version is created
- Subsequent versions can be added via AWS Console, CLI, or CI/CD
