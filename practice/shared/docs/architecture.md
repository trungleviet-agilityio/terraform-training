# Serverless Architecture Overview

This practice implements a production-style AWS serverless backend with clear layering and multi-environment composition.

**Architecture Diagram**: See `diagrams/architecture.png`

## Architecture Layers

The infrastructure is organized into three layers, each deployed independently:

### 10_core - Foundation Layer
Shared foundation resources:
- **S3 Bucket**: Terraform state backend storage
  - Versioning enabled
  - Server-side encryption (AES256)
  - Public access blocked
  - Lifecycle rules for old versions
- **DynamoDB Table**: Terraform state locking
  - Pay-per-request billing mode
  - Primary key: `LockID` (string)
  - Server-side encryption enabled
  - **Note**: This is for Terraform state locking, NOT application data
- **CloudWatch Log Retention**: Default log retention policy (14 days)
- **Route53 DNS** (optional): Hosted zone and ACM certificate for custom domains
  - Supports both default region and us-east-1 (for API Gateway certificates)
- **AWS Secrets Manager**: Secrets for CI/CD automation
  - Backend bucket name secret: `/practice/{env}/backend-bucket`
  - Terraform variables secrets for each layer: `/practice/{env}/{layer}/terraform-vars`
  - Optional KMS encryption (uses AWS default key if not specified)
- Standard tags and naming conventions
- AWS account/region data sources

**Deployment Order**: Must be deployed **first** before other layers.

### 20_infra - Platform Services Layer
Platform services that applications depend on:
- **API Gateway HTTP API**
  - Optional custom domain with Route53 integration
  - Automatic DNS record creation when DNS module is configured
  - Default endpoint: `https://{api-id}.execute-api.{region}.amazonaws.com`
- **SQS Queues**
  - Standard queue for message processing
  - Dead Letter Queue (DLQ) for failed messages
  - CloudWatch alarm for DLQ message monitoring (optional)
- **DynamoDB Tables** (optional): Shared application data storage
  - Key-value tables for simple lookups
  - Time-series tables with TTL support
  - Tables created only if configured in `terraform.tfvars`
- **IAM Roles and Policies** for Lambda functions
  - Lambda execution roles (API, Cron, Worker)
  - DynamoDB access policies (conditional, only if tables exist)
  - SQS access policies (always created)
  - Secrets Manager access policies (for secret consumption)
- **OIDC Provider** (optional): GitHub Actions authentication
  - Creates OIDC provider for GitHub Actions
  - Enables passwordless CI/CD authentication
  - Creates Terraform plan/apply IAM roles (if configured)

**Note**: EventBridge schedules are **NOT** created in this layer. Schedule creation is handled in `30_app` layer to avoid circular dependencies. Schedule expression configuration can still be defined in `terraform.tfvars` and passed to `30_app`.

**Dependencies**: Requires `10_core` outputs (tags, account ID, region, DNS certificate ARN if custom domain enabled, backend bucket/table ARNs).

**Remote State Usage**: Uses `terraform_remote_state` to automatically retrieve backend configuration from `10_core` layer and DNS certificate for custom domain setup. See `deploy/20_infra/environments/dev/main.tf` for implementation.

**Outputs**: Exposes Lambda role ARNs, API Gateway ID/ARN, SQS queue ARN, and DynamoDB table ARNs for `30_app` layer consumption via remote state.

### 30_app - Application Layer
Application workloads and compute resources:
- Lambda functions (FastAPI API, SQS worker, cron producer)
- Event source mappings and triggers
- Lambda layers (for zip deployment mode)

**Dependencies**: Requires `10_core` and `20_infra` outputs (including Lambda role ARNs, API Gateway, SQS, DynamoDB).

**Remote State Usage**: Uses `terraform_remote_state` to automatically retrieve SQS queue ARN, Lambda role ARNs, API Gateway ID/execution ARN, and DynamoDB table information from `20_infra` layer. See `deploy/30_app/environments/dev/main.tf` for implementation.

**Integration Creation**: API Gateway integrations and EventBridge schedules are created **within the 30_app layer** to avoid circular dependencies. The API Gateway HTTP API itself is created in `20_infra`, but routes, integrations, and Lambda permissions are created in `30_app` where the Lambda functions are defined.

#### Lambda Module Structure

The application layer follows a modular architecture with reusable components:

**Components** (`deploy/components/`):
- `lambda_python_module`: Packages Python Lambda modules into Lambda layers and application zip files (creates layers for dependencies, separates code from dependencies)
- `lambda_fastapi_server`: FastAPI Lambda wrapper component with optional Function URL support
- `lambda_cron_server`: Cron Lambda wrapper component for EventBridge schedules
- `lambda_sqs_worker`: SQS worker Lambda wrapper component with event source mapping
- `api_gateway_integration`: API Gateway integration component (creates integration, route, and Lambda permission)
- `eventbridge_target`: EventBridge schedule component (creates schedule with Lambda target and IAM role)

**Modules** (`deploy/30_app/modules/`):
- `runtime_code_modules`: Packages all Lambda source code and runtime modules using `lambda_python_module` component
- `api_server`: API Lambda module (uses `lambda_fastapi_server` component)
- `cron_server`: Cron Lambda module (uses `lambda_cron_server` component)
- `worker`: Worker Lambda module (uses `lambda_sqs_worker` component)

**Note**: IAM roles for Lambda functions are created in the `20_infra` layer and consumed via remote state.

**Lambda Functions**:
1. **API Server** (`api_server`): FastAPI application for HTTP API requests
   - Handler: `api_server.lambda_handler`
   - Triggered by: API Gateway (HTTP API created in `20_infra`, integration created in `30_app`)
   - Integration: API Gateway routes and integration created in `30_app` using `api_gateway_integration` component

2. **Cron Server** (`cron_server`): Scheduled tasks via EventBridge
   - Handler: `cron_server.lambda_handler`
   - Triggered by: EventBridge schedule (created in `30_app` layer using `eventbridge_target` component)
   - Integration: EventBridge schedule created in `30_app` to avoid circular dependencies

3. **Worker** (`worker`): Processes messages from SQS queue
   - Handler: `worker.lambda_handler`
   - Triggered by: SQS event source mapping (created automatically)
   - Outputs: Function ARN and event source mapping ID

**Component Usage Flow**:
```
src/runtime/          src/lambda/
    ↓                      ↓
practice_util         api_server, worker, cron_server
    ↓                      ↓
runtime_code_modules (uses lambda_python_module component)
    ↓ (outputs layer ARNs, app zip paths, signatures.json)
20_infra layer (creates IAM roles and policies)
    ↓ (outputs role ARNs via remote state)
30_app layer (consumes role ARNs)
    ↓
api_server/cron_server/worker modules
    ├─ api_server → uses lambda_fastapi_server component + practice_util layer
    ├─ cron_server → uses lambda_cron_server component + practice_util layer
    └─ worker → uses lambda_sqs_worker component + practice_util layer
    ↓
Lambda Functions created (using roles from 20_infra, layers from runtime_code_modules)
    ↓
Integration components (in 30_app/main)
    ├─ api_gateway_integration → connects API Gateway to API Lambda
    └─ eventbridge_target → creates EventBridge schedule with cron Lambda target
```

See individual module README files for detailed usage examples.

### Component vs Module Distinction

**Components** (`deploy/components/`):
- Reusable, single-purpose building blocks that create AWS resources
- Low-level abstractions that encapsulate specific Lambda patterns
- Shared across the entire project
- Examples: `lambda_python_module`, `lambda_fastapi_server`, `lambda_cron_server`, `lambda_sqs_worker`, `api_gateway_integration`, `eventbridge_target`

**Modules** (`deploy/30_app/modules/`):
- Orchestrate components to provide higher-level abstractions
- Specific to the application layer (`30_app`)
- Combine multiple components and resources to create complete Lambda functions
- Examples: `runtime_code_modules`, `api_server`, `cron_server`, `worker`

**Component Design Principle**: Each component follows a single-responsibility principle - one component = one Lambda pattern or packaging mechanism.

### Component Usage Examples

**Example 1: runtime_code_modules uses lambda_python_module**

The `runtime_code_modules` module uses the `lambda_python_module` component to package runtime modules and Lambda functions with layer support:

```hcl
# In runtime_code_modules/main.tf
# Package practice_util runtime module (creates Lambda layer)
module "practice_util" {
  source = "../../../components/lambda_python_module"
  package_root   = "${path.root}/../../../../src/runtime/practice_util"
  package_name   = "practice_util"
  python_version = "3.13"
  use_s3         = false
}

# Package API Server Lambda code (uses practice_util layer)
module "api_server_package" {
  source = "../../../components/lambda_python_module"
  package_root   = "${path.root}/../../../../src/lambda/api_server"
  package_name   = "api_server"
  python_version = "3.13"
  use_s3         = false
}
```

**Example 2: api_server module uses lambda_fastapi_server**

The `api_server` module uses the `lambda_fastapi_server` component to create the FastAPI Lambda function:

```hcl
# In api_server/main.tf
module "lambda_fastapi_server" {
  source = "../../../components/lambda_fastapi_server"
  function_name      = var.function_name
  package_zip_path   = var.package.zip_path
  package_zip_hash   = var.package.zip_hash
  execution_role_arn = var.execution_role_arn
  # ... other configuration
}
```

**Example 3: worker module uses lambda_sqs_worker**

The `worker` module uses the `lambda_sqs_worker` component to create the SQS worker Lambda with automatic event source mapping:

```hcl
# In worker/main.tf
module "lambda_sqs_worker" {
  source = "../../../components/lambda_sqs_worker"
  function_name      = var.function_name
  package_zip_path   = var.package.zip_path
  sqs_queue_arn      = var.sqs_queue_arn
  execution_role_arn = var.execution_role_arn
  # ... other configuration
}
```

### Component Architecture Diagram

```
Component Architecture:
┌───────────────────────────────────────────────────────────────┐
│ Components (deploy/components/)                               │
├───────────────────────────────────────────────────────────────┤
│ lambda_python_module                                          │
│   └─ Packages Python modules → Lambda layers + app zips       │
│      (creates layers for dependencies, separates code)        │
│                                                               │
│ lambda_fastapi_server                                         │
│   └─ Creates FastAPI Lambda + Function URL (optional)         │
│                                                               │
│ lambda_cron_server                                            │
│   └─ Creates cron Lambda for EventBridge                      │
│                                                               │
│ lambda_sqs_worker                                             │
│   └─ Creates SQS worker Lambda + event source mapping         │
│                                                               │
│ api_gateway_integration                                       │
│   └─ Creates API Gateway integration + route + permission     │
│                                                               │
│ eventbridge_target                                            │
│   └─ Creates EventBridge schedule + IAM role + target         │
└───────────────────────────────────────────────────────────────┘
                          ↓ used by
┌───────────────────────────────────────────────────────────────┐
│ Modules (deploy/30_app/modules/)                              │
├───────────────────────────────────────────────────────────────┤
│ runtime_code_modules                                          │
│   └─ Uses: lambda_python_module (×4)                          │
│      (packages practice_util, api_server, cron_server, worker)│
│                                                               │
│ api_server                                                    │
│   └─ Uses: lambda_fastapi_server + practice_util layer        │
│                                                               │
│ cron_server                                                   │
│   └─ Uses: lambda_cron_server + practice_util layer           │
│                                                               │
│ worker                                                        │
│   └─ Uses: lambda_sqs_worker + practice_util layer            │
└───────────────────────────────────────────────────────────────┘
                          ↓ used by
┌───────────────────────────────────────────────────────────────┐
│ Main Module (deploy/30_app/main/)                             │
├───────────────────────────────────────────────────────────────┤
│ Uses integration components:                                  │
│   ├─ api_gateway_integration                                  │
│   └─ eventbridge_target                                       │
└───────────────────────────────────────────────────────────────┘
```

### Request Flow

```
User
  ↓
Route53 DNS (optional, for custom domain)
  ↓
API Gateway (HTTP API)
  ├─ Custom Domain: https://api.dev.example.com (if configured)
  └─ Default Endpoint: https://{api-id}.execute-api.{region}.amazonaws.com
  ↓
Lambda (FastAPI API)
  ├─→ DynamoDB (optional persistence)
  └─→ SQS Queue
       ↓
       Lambda (SQS Worker)
```

### Scheduled Flow

```
EventBridge (Cron Schedule)
  ↓
Lambda (Producer)
  ↓
SQS Queue
  ↓
Lambda (SQS Worker)
```

### Packaging Strategy

**Zip + Lambda Layer**:
- Function code packaged as zip file
- Dependencies packaged as Lambda Layer
- Lambda Layer shared across multiple functions for efficiency
- Suitable for Python dependencies and standard libraries
- Function zip size limit: 50MB (uncompressed)
- Layer size limit: 250MB (uncompressed)

## AWS Services Used

### Compute
- **Lambda**: Serverless functions for API, workers, and scheduled tasks
- **Lambda Layers**: Shared code and dependencies packaged as reusable layers

### Networking & API
- **API Gateway**: HTTP API endpoint for public access
  - Default endpoint: `https://{api-id}.execute-api.{region}.amazonaws.com`
  - Optional custom domain: `https://api.{environment}.{domain}` (requires DNS and ACM certificate)
- **Route53**: DNS management (optional, for custom domains)
  - Hosted zone for subdomain: `{environment}.{domain}`
  - ACM certificate for SSL/TLS (wildcard: `*.{environment}.{domain}`)
  - Automatic Route53 A record for API Gateway custom domain

### Messaging & Events
- **SQS**: Message queue for asynchronous processing
  - Standard queue for reliable message delivery
  - Dead Letter Queue (DLQ) for failed messages
- **EventBridge**: Event-driven scheduling (cron-based)

### Storage & Database
- **DynamoDB**: NoSQL database for application data
  - Key-value tables for simple lookups (user data, configuration)
  - Time-series tables for events, logs, metrics (with TTL support)
  - Tables created in `20_infra` layer as shared resources (optional)
  - Lambda functions have IAM permissions to read/write DynamoDB tables
- **S3**: 
  - Terraform state storage (backend) - created in `10_core` layer
  - Versioning, encryption, and lifecycle management enabled

### Security & Access
- **IAM**: Roles and policies for Lambda functions and GitHub Actions
  - Lambda execution roles with least-privilege policies
  - GitHub Actions OIDC roles for CI/CD (optional)
- **KMS**: Optional customer-managed keys for Secrets Manager encryption
  - If not specified, AWS Secrets Manager uses the default AWS-managed key
- **Secrets Manager**: Secure storage for sensitive configuration
  - Backend bucket names for CI/CD
  - Terraform variables for automated workflows
  - Application secrets (API keys, database credentials, etc.)

### Observability
- **CloudWatch Logs**: Centralized logging for all Lambda functions
  - Log retention policy: 14 days (configurable, set in `10_core` layer)
  - Automatic log group creation for Lambda functions
- **CloudWatch Metrics & Alarms**: Service metrics and monitoring
  - SQS DLQ alarm (monitors failed messages in Dead Letter Queue)
  - Lambda function metrics (invocations, errors, duration)
  - API Gateway metrics (requests, latency, errors)

### State Management
- **S3**: Remote state storage (created in `10_core` layer)
  - Bucket naming: `{project_name}-tf-state-{environment}-{account_id}`
  - State key structure: `core/terraform.tfstate`, `infra/terraform.tfstate`, `app/terraform.tfstate`
  - Versioning enabled for state file history
  - Encryption at rest (AES256)
  - Lifecycle rules to expire old versions after 90 days
- **DynamoDB**: State locking to prevent concurrent modifications
  - Table name: `{project_name}-tf-locks`
  - Primary key: `LockID` (string)
  - Pay-per-request billing mode
  - Server-side encryption enabled

## Data Flow

1. **API Request Flow**:
   - User sends HTTP request (via custom domain or default endpoint)
   - Route53 DNS resolves custom domain (if configured)
   - API Gateway routes to FastAPI Lambda function
   - Lambda processes request (may read/write DynamoDB)
   - Lambda may enqueue messages to SQS for async processing

2. **Asynchronous Processing**:
   - SQS delivers messages to Worker Lambda via event source mapping
   - Worker Lambda processes messages (may write to DynamoDB)
   - Failed messages are sent to DLQ after max retries

3. **Scheduled Tasks**:
   - EventBridge triggers Producer Lambda on schedule (cron)
   - Producer Lambda enqueues tasks to SQS
   - Tasks are processed by Worker Lambda

### DynamoDB Table Structure Examples

**Key-Value Table** (user-data):
- Partition Key: `user_id` (String)
- Use cases: User profiles, configuration data, simple lookups

**Time-Series Table** (events):
- Partition Key: `event_type` (String)
- Sort Key: `timestamp` (Number)
- TTL: Enabled on `ttl` attribute
- Use cases: Event logs, metrics, time-series data

## Environment Structure

Each layer maintains its own environment configurations:
- `deploy/{layer}/environments/dev/`
- `deploy/{layer}/environments/stage/`
- `deploy/{layer}/environments/prod/`

Each environment:
- Maintains separate Terraform state
- Uses environment-specific variables
- Can have different resource configurations

## Security Considerations

- **IAM Least Privilege**: Each Lambda function has minimal required permissions
- **Encryption**: Optional KMS CMK for encrypting sensitive data
- **State Security**: Terraform state encrypted in S3 with versioning enabled
- **Network Security**: API Gateway provides HTTPS endpoints
- **Secret Management**: AWS Secrets Manager for storing and managing secrets

### Secret Management Strategy

Secrets are managed using a layered approach with AWS Secrets Manager:

#### Layer Responsibilities

| Layer | Secret Handling | Examples |
|-------|----------------|----------|
| **10_core** | Create and manage Secrets Manager secrets | `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` |
| **20_infra** | Grant access permissions via IAM policies | Lambda execution roles get `secretsmanager:GetSecretValue` |
| **30_app** | Consume secrets at runtime (env vars or SDK) | Lambda reads `DATABASE_URL`, `API_KEY`, etc. |

#### Why This Pattern Works

1. **Secrets created once** in `10_core` - Single source of truth
2. **Access granted** in `20_infra` - Least-privilege IAM policies
3. **Secrets consumed** in `30_app` - Runtime access via environment variables or AWS SDK

#### Secret Examples

**10_core** creates secrets:
```hcl
secrets = {
  api_key = {
    description   = "API key for external service"
    secret_string = null  # Set via AWS Console or CI/CD
  }
}
```

This creates a secret named `/practice/<environment>/api-key` in AWS Secrets Manager.

**20_infra** grants Lambda access:
```hcl
resource "aws_iam_role_policy" "lambda_secrets" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [data.terraform_remote_state.core.outputs.api_key_secret_arn]
    }]
  })
}
```

**30_app** consumes secrets:
```hcl
resource "aws_lambda_function" "api" {
  environment {
    variables = {
      ENV                = "dev"
      API_KEY_SECRET_ARN = data.terraform_remote_state.core.outputs.api_key_secret_arn
    }
  }

  # IAM policy statements for secret access
  iam_policy_statements = [
    {
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [data.terraform_remote_state.core.outputs.api_key_secret_arn]
    }
  ]
}
```

**Lambda Code Example**:
```python
import boto3
import json
import os

def lambda_handler(event, context):
    secret_arn = os.environ.get('API_KEY_SECRET_ARN')
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    secret_value = json.loads(response['SecretString'])
    # Use secret_value
```

**Best Practices**:
- Never store secrets in Terraform variables or code (use `secret_string = null`)
- Use Secrets Manager for all sensitive data (API keys, database credentials, tokens)
- Pass secret ARNs (not values) as environment variables
- Rotate secrets regularly
- Use separate secrets per environment
- Grant access only to resources that need it
- Monitor secret access via CloudTrail

**See**: `practice/deploy/10_core/modules/secrets/README.md` for detailed module documentation.

## State & Security

- **Remote State**: Stored in S3 with DynamoDB state locking
- **State Isolation**: Each layer maintains separate state files
- **Backend Configuration**: Configured per environment via `backend.tfvars`
- **Remote State Usage**: Layers use `terraform_remote_state` to share outputs automatically (e.g., 20_infra gets backend config from 10_core, 30_app gets SQS ARN from 20_infra)
- **CI/CD Access**: GitHub Actions uses OIDC to assume IAM roles (no static credentials)

**See**: `shared/docs/terraform-state-and-backend.md` for comprehensive guide on Terraform state and remote state usage.

## Roadmap (Future Enhancements)

- **Custom Domain**: Route53 + ACM for custom API Gateway domain (implemented, optional)
- **VPC Integration**: Private subnets for Lambda functions if needed
- **WAF**: Web Application Firewall in front of API Gateway
- **Additional Persistence**: RDS or ElastiCache if required
- **Multi-Region**: Disaster recovery and global distribution
- **Monitoring**: CloudWatch dashboards and alarms
- **X-Ray**: Distributed tracing for Lambda functions

## DNS and Custom Domain Setup

### Practice Mode (No Custom Domain)

**Default Behavior**: API Gateway works immediately with default endpoint:
- Endpoint: `https://{api-id}.execute-api.ap-southeast-1.amazonaws.com`
- No DNS or certificate setup required
- Perfect for development and testing

### Production Mode (With Custom Domain)

**Optional Setup**: Enable custom domain for professional API endpoint:

1. **Configure DNS in 10_core layer**:
   ```hcl
   # In 10_core/environments/dev/terraform.tfvars
   dns_config = {
     domain_name = "example.com"  # Creates dev.example.com hosted zone
   }
   ```

2. **For API Gateway**: Certificate MUST be in us-east-1. Set `use_us_east_1_certificate = true`:
   ```hcl
   # In 10_core/environments/dev/terraform.tfvars
   use_us_east_1_certificate = true

   dns_config = {
     domain_name = "example.com"
   }
   ```

   The provider alias (`aws.us_east_1`) is already configured in `providers.tf`. The module automatically uses it when `use_us_east_1_certificate` is set to `true`.

3. **Automatic Integration**: `20_infra` layer automatically:
   - Reads certificate ARN from `10_core` remote state
   - Creates API Gateway custom domain
   - Creates Route53 A record
   - Maps API to custom domain

4. **Result**: API accessible at `https://api.dev.example.com`

**See**: 
- `deploy/10_core/modules/dns/README.md` - DNS module documentation
- `deploy/20_infra/modules/api-gateway/README.md` - API Gateway custom domain setup

## See Also

- [CI/CD Documentation](ci-cd.md) - Continuous integration workflows
- [Remote State Documentation](remote-state.md) - Terraform state management
- [CLI Tool Documentation](cb-cli.md) - Developer CLI usage
- [Operations Runbook](runbook.md) - Rollback procedures, log inspection, and troubleshooting
