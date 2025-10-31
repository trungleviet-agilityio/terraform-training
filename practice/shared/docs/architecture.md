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

### 30_app - Application Layer
Application workloads and compute resources:
- Lambda functions (FastAPI API, SQS worker, cron producer)
- Event source mappings and triggers
- Function-specific IAM roles
- Lambda layers (for zip deployment mode)

**Dependencies**: Requires `10_core` and `20_infra` outputs.

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
- **DynamoDB**: NoSQL database for application data (optional)
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
- **Secret Management**: Use AWS Secrets Manager or Parameter Store for sensitive configuration

## State & Security

- **Remote State**: Stored in S3 with DynamoDB state locking
- **State Isolation**: Each layer maintains separate state files
- **Backend Configuration**: Configured per environment via `backend.tfvars`
- **CI/CD Access**: GitHub Actions uses OIDC to assume IAM roles (no static credentials)

## Roadmap (Future Enhancements)

- **Custom Domain**: Route53 + ACM for custom API Gateway domain
- **VPC Integration**: Private subnets for Lambda functions if needed
- **WAF**: Web Application Firewall in front of API Gateway
- **Additional Persistence**: RDS or ElastiCache if required
- **Multi-Region**: Disaster recovery and global distribution
- **Monitoring**: CloudWatch dashboards and alarms
- **X-Ray**: Distributed tracing for Lambda functions
