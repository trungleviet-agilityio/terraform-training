## Terraform Practice (AWS Serverless)

### Problem This Practice Solves
- Learn production-style Terraform with a realistic serverless backend on AWS: layered code, remote state, and CI/CD.
- Key topics: FastAPI on Lambda (zip vs container), handling large deps via Lambda Layer or ECR images, async with SQS, cron with EventBridge.

### Architecture Overview
- Ingress: API Gateway HTTP API
- Compute: Lambda (FastAPI API), Lambda (SQS worker), Lambda (cron producer)
- Messaging: SQS queue + DLQ
- Scheduling: EventBridge (cron) → producer Lambda → SQS
- Packaging: Zip + Lambda Layer, or container image in ECR
- State: S3 backend + DynamoDB lock (bootstrap)

```
Users ──> API Gateway ──> Lambda (FastAPI API)
                         └───────────────▶ SQS (queue + DLQ) ──▶ Lambda (SQS worker)

EventBridge (cron) ───────────────────────────────────────────▶ Lambda (producer) ─▶ SQS

ECR (container image mode) | Lambda Layer (zip mode)
```

### Folder Layout
```
practice/
  10_core/     # Foundation: tags, optional KMS, shared settings
  20_infra/    # Platform: API Gateway, SQS, EventBridge, ECR
  30_app/      # Workloads: API Lambda, SQS worker, cron producer
  modules/     # Reusable modules (to be added)
  components/  # Reusable components (to be added)
  envs/        # dev / stage / prod (added in a later task)
  scripts/
    bootstrap_state.sh
```

### Remote State Bootstrap
Use the helper script to provision S3 + DynamoDB:

```bash
./scripts/bootstrap_state.sh \
  --bucket tt-practice-tf-state-<unique> \
  --table tt-practice-tf-locks \
  --region us-east-1
```

Backends are configured in environment folders via `backend "s3" {}` and set using `-backend-config` flags.

### Next Steps
1) Configure environments (dev, stage, prod)
2) Add platform services (API Gateway, SQS, EventBridge, ECR)
3) Add workloads (API Lambda, SQS worker, cron producer)
4) Add CI (fmt/validate/plan/apply) and build jobs (zip/container)

See also: `docs/architecture.*` for the diagram source and artifact.
