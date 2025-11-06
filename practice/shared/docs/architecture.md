# Serverless Architecture Overview

This practice implements a production-style AWS serverless backend with clear layering and multi-environment composition.

**Architecture Diagram**: See `diagrams/architecture.png`

## Architecture Layers

The infrastructure is organized into three layers, each deployed independently:

### 10_core - Foundation Layer
Shared foundation resources:
- Standard tags and naming conventions
- Optional KMS CMK for encryption
- Base IAM roles and policies
- CloudWatch log retention settings
- AWS account/region data sources

**Deployment Order**: Must be deployed **first** before other layers.

### 20_infra - Platform Services Layer
Platform services that applications depend on:
- API Gateway HTTP API
- SQS queues (standard + DLQ)
- EventBridge schedules

**Dependencies**: Requires `10_core` outputs (tags, account ID, region).

**Remote State Usage**: Uses `terraform_remote_state` to automatically retrieve backend configuration from `10_core` layer. See `deploy/20_infra/environments/dev/main.tf` for implementation.

### 30_app - Application Layer
Application workloads and compute resources:
- Lambda functions (FastAPI API, SQS worker, cron producer)
- Event source mappings and triggers
- Function-specific IAM roles
- Lambda layers (for zip deployment mode)

**Dependencies**: Requires `10_core` and `20_infra` outputs.

**Remote State Usage**: Uses `terraform_remote_state` to automatically retrieve SQS queue ARN from `20_infra` layer. See `deploy/30_app/environments/dev/main.tf` for implementation.

#### Lambda Module Structure

The application layer follows a modular architecture with reusable components:

**Components** (`deploy/components/`):
- `lambda_simple_package`: Packages Lambda source code into zip files
- `lambda_fastapi_server`: FastAPI Lambda wrapper component
- `lambda_cron_server`: Cron Lambda wrapper component
- `lambda_sqs_worker`: SQS worker Lambda wrapper component

**Modules** (`deploy/30_app/modules/`):
- `runtime_code_modules`: Packages all Lambda source code
- `lambda_roles`: Creates IAM execution roles for Lambda functions
- `api_server`: API Lambda module (uses `lambda_fastapi_server` component)
- `cron_server`: Cron Lambda module (uses `lambda_cron_server` component)
- `worker`: Worker Lambda module (uses `lambda_sqs_worker` component)

**Lambda Functions**:
1. **API Server** (`api_server`): FastAPI application for HTTP API requests
   - Handler: `api_server.lambda_handler`
   - Triggered by: API Gateway (configured in `20_infra` layer)
   - Outputs: Function ARN for API Gateway integration

2. **Cron Server** (`cron_server`): Scheduled tasks via EventBridge
   - Handler: `cron_server.lambda_handler`
   - Triggered by: EventBridge schedule (configured in `20_infra` layer)
   - Outputs: Function ARN for EventBridge integration

3. **Worker** (`worker`): Processes messages from SQS queue
   - Handler: `worker.lambda_handler`
   - Triggered by: SQS event source mapping (created automatically)
   - Outputs: Function ARN and event source mapping ID

**Component Usage Flow**:
```
runtime_code_modules (packages source code)
    ↓
lambda_roles (creates IAM roles)
    ↓
api_server/cron_server/worker modules (use components)
    ↓
Lambda functions created
```

See individual module README files for detailed usage examples.

## Component Architecture

### Request Flow

```
User
  ↓
API Gateway (HTTP API)
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
- **Route53**: DNS management (optional, for custom domains)

### Messaging & Events
- **SQS**: Message queue for asynchronous processing
  - Standard queue for reliable message delivery
  - Dead Letter Queue (DLQ) for failed messages
- **EventBridge**: Event-driven scheduling (cron-based)

### Storage & Database
- **DynamoDB**: NoSQL database for application data
  - Key-value tables for simple lookups (user data, configuration)
  - Time-series tables for events, logs, metrics (with TTL support)
  - Tables created in `20_infra` layer as shared resources
  - Lambda functions have IAM permissions to read/write DynamoDB tables
- **S3**: Terraform state storage (backend)

### Security & Access
- **IAM**: Roles and policies for Lambda functions
- **KMS**: Customer-managed keys for encryption (optional)

### Observability
- **CloudWatch**: Logs and metrics for all services
- **CloudWatch Logs**: Centralized logging

### State Management
- **S3**: Remote state storage
- **DynamoDB**: State locking to prevent concurrent modifications

## Data Flow

1. **API Request Flow**:
   - User sends HTTP request to API Gateway
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

- **Custom Domain**: Route53 + ACM for custom API Gateway domain
- **VPC Integration**: Private subnets for Lambda functions if needed
- **WAF**: Web Application Firewall in front of API Gateway
- **Additional Persistence**: RDS or ElastiCache if required
- **Multi-Region**: Disaster recovery and global distribution
- **Monitoring**: CloudWatch dashboards and alarms
- **X-Ray**: Distributed tracing for Lambda functions
