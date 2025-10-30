## Serverless Architecture Overview

This practice implements a production-style AWS serverless backend with clear layering and multi-environment composition.

Diagram: see `practice/shared/diagrams/architecture.png` (your drawn diagram).

### Layers
- 10_core: shared foundation (tags, log retention, optional KMS; artifacts bucket planned).
- 20_infra: platform services (API Gateway HTTP API, SQS + DLQ, EventBridge rule, ECR repo).
- 30_app: workloads (FastAPI API Lambda; SQS Worker Lambda; Cron Producer Lambda) and event wiring.

Environments compose these layers in `practice/envs/{dev,stage,prod}`.

### Components in the Diagram
- Route53 DNS (optional/custom domain for API; can be added later).
- API Gateway: public entrypoint routing to the API Lambda.
- Lambda Functions:
  - FastAPI API handler (zip + layer or container image from ECR).
  - SQS Worker consuming messages from the queue.
  - Cron Producer triggered by EventBridge to enqueue tasks.
- DynamoDB: optional application persistence (pattern shown in diagram; can be added in a later task).
- SQS: standard queue with DLQ for failed messages.
- EventBridge: cron-based scheduler invoking the Producer Lambda.
- CloudWatch: logs and metrics for all functions and services.

### Packaging Strategies
- Zip + Lambda Layer for smaller dependencies to keep function zip lean.
- Container Image (ECR) for large/native dependencies; tagged by commit SHA.

### State & Security
- Terraform remote state in S3 with DynamoDB state locking (bootstrapped outside Terraform backends).
- IAM roles with least privilege per function; GitHub Actions OIDC for CI/CD access.

### Data Flow
1) User calls API Gateway → API Lambda processes request; may read/write DynamoDB and/or enqueue messages to SQS.
2) SQS delivers messages to Worker Lambda via event source mapping.
3) EventBridge (cron) regularly triggers Producer Lambda to enqueue scheduled tasks to SQS.

### Roadmap (Incremental Enhancements)
- Custom domain + ACM (API Gateway) via Route53.
- VPC integration for Lambdas (private subnets) if needed.
- WAF in front of API Gateway.
- Additional persistence (RDS/ElastiCache) if required by workloads.


