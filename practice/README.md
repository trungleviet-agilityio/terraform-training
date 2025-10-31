# Terraform Practice Project - AWS Serverless Architecture

## Overview

This practice project implements a production-style AWS serverless infrastructure using Terraform, organized into clear layers with multi-environment support.

**Architecture**: API Gateway → Lambda (FastAPI) → SQS → Lambda Workers, with EventBridge cron scheduling.

**Diagram**: See `shared/diagrams/architecture.png`

## Project Structure

```
practice/
├── deploy/              # Infrastructure as Code (Terraform)
│   ├── 10_core/         # Foundation layer (KMS, tags, base resources)
│   │   ├── main/        # Core module implementation
│   │   ├── environments/# Per-environment configs (dev/stage/prod)
│   │   └── modules/     # Reusable sub-modules
│   ├── 20_infra/        # Platform services (API Gateway, SQS, EventBridge)
│   ├── 30_app/          # Application workloads (Lambda functions)
│   ├── components/      # Shared reusable components
│   └── scripts/         # Deployment helper scripts
├── src/                 # Application source code
│   ├── lambda/          # Lambda function code
│   ├── dynamodb/        # DynamoDB schemas/scripts
│   └── utils/           # Shared utilities
├── shared/              # Shared documentation
│   ├── diagrams/        # Architecture diagrams
│   └── docs/            # Documentation (architecture.md, ci-cd.md)
└── bin/                 # Developer CLI tools
    └── cb               # Build/Deploy CLI (to be implemented)
```

## Architecture Layers

### 10_core
Foundation resources shared across all environments:
- Standard tags and naming conventions
- Optional KMS CMK for encryption
- Base IAM roles and policies
- CloudWatch log retention settings

### 20_infra
Platform services that applications depend on:
- API Gateway HTTP API
- SQS queues (standard + DLQ)
- EventBridge schedules

### 30_app
Application workloads:
- Lambda functions (FastAPI API, SQS worker, cron producer)
- Event source mappings and triggers
- Function-specific IAM roles

## Environments

Each layer maintains its own environment configurations:
- `environments/dev/` - Development environment
- `environments/stage/` - Staging environment
- `environments/prod/` - Production environment

Environments import their respective `main/` modules and pass environment-specific variables.

## Getting Started

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- AWS credentials with appropriate permissions

### Bootstrap Remote State

Create S3 bucket and DynamoDB table for Terraform state:

```bash
# Bootstrap script to be created
./deploy/scripts/bootstrap_state.sh \
  --bucket tt-practice-tf-state-<unique> \
  --table tt-practice-tf-locks \
  --region us-east-1
```

### Deploy Infrastructure

Deploy layers in order (core → infra → app) for each environment:

```bash
cd deploy/10_core/environments/dev
terraform init -backend-config=backend.tfvars
terraform plan -var-file=terraform.tfvars
terraform apply
```

Repeat for `20_infra` and `30_app`.

### Create New Environment

Use the helper script to scaffold a new environment for a layer:

```bash
./deploy/scripts/create_environment.sh <layer> <environment>
# Example: ./deploy/scripts/create_environment.sh 20_infra staging
```

### Developer CLI

The `bin/cb` CLI will provide shortcuts for build/test/deploy workflows (to be implemented).

## Documentation

- **Architecture**: `shared/docs/architecture.md`
- **CI/CD**: `shared/docs/ci-cd.md`
- **Diagram**: `shared/diagrams/architecture.png`

## Next Steps

This is the initial project structure. Implementation will proceed layer by layer:

1. [DONE] Project structure and scaffolding
2. [TODO] Core layer resources (KMS, tags, base IAM)
3. [TODO] Infrastructure layer (API Gateway, SQS, EventBridge)
4. [TODO] Application layer (Lambda functions with Lambda Layers)
5. [TODO] CI/CD workflows (GitHub Actions)
6. [TODO] Developer CLI (`cb` tool)
