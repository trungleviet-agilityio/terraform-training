# Terraform Basics – Learning Notes

These notes summarize key concepts and workflows across basics modules (`module-01` … `module-07`) in this repo.

## What Terraform Is
- Infrastructure as Code (IaC) tool for provisioning and managing cloud resources declaratively.
- Desired state is defined in `.tf` files; Terraform computes a plan to reach that state.
- Core ideas: providers, resources, data sources, variables, outputs, state, modules.

## Core Workflow
1. `terraform init` — install providers/modules, set up backend.
2. `terraform fmt -recursive` — format code.
3. `terraform validate` — static validation of configs.
4. `terraform plan [-out tfplan]` — preview changes.
5. `terraform apply [tfplan]` — execute plan.
6. `terraform destroy` — remove managed infrastructure.

## Project Structure (typical)
- `provider.tf` — provider config and required versions.
- `variables.tf` — inputs (with types, defaults, validation).
- `locals.tf` — derived values.
- `main.tf` — resources and module calls.
- `outputs.tf` — export values.
- `terraform.tfvars` — environment-specific inputs (avoid committing secrets).
- `.terraform.lock.hcl` — provider dependency lockfile (commit this).
- `.terraform/` — local cache (do not commit).

## Providers
- Configure which cloud/API to use.
```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}
```

## Resources vs Data Sources
- Resources: create/update/destroy infrastructure.
```hcl
resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name
  tags   = local.default_tags
}
```
- Data sources: read-only lookups of existing info (no changes).
```hcl
data "aws_vpc" "prod" {
  tags = { Env = "Prod" }
}
```

## Variables, Locals, Outputs
```hcl
variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

locals {
  default_tags = { ManagedBy = "Terraform" }
}

output "bucket_name" {
  value = aws_s3_bucket.website.bucket
}
```

## State
- Tracks the real-world mapping of resources; lives in `terraform.tfstate` (local) or remote backend (recommended).
- Remote backends enable collaboration and locking (e.g., S3 + DynamoDB).
- Commands: `terraform state list`, `terraform state show <addr>`, `terraform refresh` (be cautious).

## Modules
- Reusable stacks; pass inputs, receive outputs.
```hcl
module "network" {
  source  = "../modules/network"
  vpc_cidr = "10.0.0.0/16"
}
```
- Pin versions when using registry modules. Keep module interfaces (vars/outputs) stable.

## Expressions and Meta-Arguments
- `for_each`, `count`, `depends_on`, `lifecycle`.
```hcl
resource "aws_s3_bucket" "b" {
  for_each = toset(var.bucket_names)
  bucket   = each.value

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}
```
- Conditionals: `condition ? a : b`
- `dynamic` blocks for repeated nested structures.

## Workspaces
- Lightweight state partitioning: `terraform workspace new dev`, `select`, `list`.
- Prefer separate backends/accounts for strict isolation; use workspaces for light multi-env.

## Module-06: S3 Static Website (High-Level)
- Create S3 bucket with website hosting enabled.
- Public-read access policy via `aws_iam_policy_document` or static JSON.
- Optional: CloudFront, Route53, TLS (beyond basics). Ensure cost cleanup.

## Module-07: Data Sources (Key Patterns)
- AMI lookup (latest Ubuntu; match architecture to instance type).
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter { name = "name"  values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"] }
  filter { name = "virtualization-type" values = ["hvm"] }
  # Add architecture filter if needed: ["x86_64"] or ["arm64"]
}
```
- Caller identity and region (useful for naming, policies).
```hcl
data "aws_caller_identity" "current" {}
data "aws_region"          "current" {}

output "account_id" { value = data.aws_caller_identity.current.account_id }
output "region"     { value = data.aws_region.current.name }
```
- VPC discovery (by tags or ID).
```hcl
data "aws_vpc" "prod" {
  tags = { Env = "Prod" }
}
```
- IAM policy generation (no hardcoded JSON).
```hcl
data "aws_iam_policy_document" "static_website" {
  statement {
    sid = "PublicReadGetObject"
    principals { type = "*", identifiers = ["*"] }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::*/*"]
  }
}
output "policy_json" { value = data.aws_iam_policy_document.static_website.json }
```
- Chaining: VPC → Subnets → AMI → EC2.

## Filtering and Tagging Best Practices
- Be specific: combine filters to avoid ambiguous matches.
- Prefer IDs for determinism when you know them.
- Maintain consistent tagging (Environment, Owner, CostCenter, App).

## Security and Safety
- Never commit secrets; prefer environment variables or secret managers.
- Use least-privilege IAM; validate `destroy` targets and costs.
- Use `-out` plan files for review/approvals; avoid `-auto-approve` in prod.

## Testing and Validation
- `terraform fmt`, `terraform validate` for hygiene.
- Optional tooling: tflint, tfsec, checkov (not mandatory for basics).
- Run small, iterative plans; review diffs carefully.

## Troubleshooting
- No results from data source: relax/refine filters; check region/account.
- Architecture mismatch: align AMI architecture with instance type.
- Credential/permission errors: verify caller identity and IAM policy.
- Drift: `plan` shows unexpected changes; reconcile or import.

## Common Commands (Cheat Sheet)
- Init/Plan/Apply/Destroy
  - `terraform init`
  - `terraform plan -out=tfplan`
  - `terraform apply tfplan`
  - `terraform destroy`
- Formatting/Linting
  - `terraform fmt -recursive`
  - `terraform validate`
- State
  - `terraform state list`
  - `terraform state show <address>`

## Repo Pointers
- Learning modules: `learning/basics/module-0x-*`
- Exercises: `exercises/basics/module-0x/*`

Keep experiments small, tag everything, and always clean up.


