# Advanced Module 07 – Managing State in Terraform

## Learning Objectives
- Understand how Terraform state maps configuration to real resources
- Import existing resources with `terraform import` and the `import` block
- Refactor resources without recreation using `terraform state mv` and `moved` blocks
- Untrack resources safely using `terraform state rm` and (TF ≥ 1.7) `removed` blocks
- Force replacements with taints and the modern `-replace` flag
- Predict plan/apply outcomes and avoid common pitfalls during state changes

## Session Notes

### 1. Why manipulate state?
- Adopt existing, manually created resources without recreating them
- Rename or reorganize resources/modules without downtime
- Hand off ownership between teams or projects
- Repair broken resources by forcing recreation

### 2. Importing existing resources
- Purpose: bring a real resource under Terraform management (adds it to state)
- Two approaches:
  - CLI: `terraform import <addr> <id>`
  - Block: `import { to = <addr>  id = <id> }`
- Example (S3 bucket):
```hcl
resource "aws_s3_bucket" "remote_state" {
  bucket = "your-remote-backend-bucket"
  tags   = { ManagedBy = "Terraform" }
}

import {
  to = aws_s3_bucket_public_access_block.remote_state
  id = aws_s3_bucket.remote_state.bucket
}

resource "aws_s3_bucket_public_access_block" "remote_state" {
  bucket = aws_s3_bucket.remote_state.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```
- Notes:
  - CLI import writes to state immediately; import block is applied on `terraform apply`
  - Import syncs real attributes into state; configuration may still differ → plan shows changes
  - For critical buckets, add `lifecycle { prevent_destroy = true }`

### 3. Moving/renaming without recreation
- Problem: renaming a resource label looks like destroy/new create
- Solutions:
  - CLI: `terraform state mv aws_instance.db_old aws_instance.db_new`
  - Block (preferred for auditable history):
```hcl
moved {
  from = aws_instance.old
  to   = aws_instance.new
}

moved {
  from = aws_instance.list[0]
  to   = aws_instance.list["instance1"]
}

moved {
  from = aws_instance.list["instance2"]
  to   = module.compute.aws_instance.this
}
```
- Tips:
  - Use quotes for indexed addresses in shells (`'aws_instance.x[0]'`)
  - Keep only meaningful `moved` history to reduce noise

### 4. Untracking resources (forget without delete)
- Use when another team/project will own the resource, or it was decommissioned outside Terraform
- Terraform 1.6 and earlier:
  - CLI only: `terraform state rm aws_s3_bucket.my_bucket`
- Terraform 1.7 and later:
  - `removed` block (documentation-friendly):
```hcl
removed {
  from = aws_s3_bucket.my_bucket
  lifecycle { destroy = false }  # forget but do not delete
}
```
- Setting `destroy = true` deletes the physical object during apply

### 5. Forcing replacement
- Legacy: `terraform taint` / `terraform untaint` (still available)
- Modern (recommended): use `-replace` flag
  - Replace one: `terraform apply -replace=aws_s3_bucket.tainted`
  - Replace dependents too: `terraform apply -replace=aws_s3_bucket.tainted -replace=aws_s3_bucket_public_access_block.from_tainted`
- Caveat: Replacements don’t always cascade; add explicit `-replace` for dependents or model with lifecycle/refs

### 6. Plan/apply expectations
- Import only writes to state; plan may show changes until config matches real state
- `moved` blocks show a “moved” action; state changes apply on `terraform apply`
- `removed destroy=false` forgets tracking; resource remains in cloud
- Forgetting via CLI or `removed` means you must import again to manage later

### 7. Common pitfalls and how to avoid
- Renaming without moving state → unintended destroy/create
  - Always use `state mv` or `moved {}`
- Importing with mismatched config → replacement in plan
  - Update config to match reality, then evolve changes explicitly
- Assuming taint/replacement cascades to dependents
  - Use multiple `-replace` flags or restructure dependencies
- Using `removed` on TF < 1.7
  - Fallback to `terraform state rm`

### 8. Generate configuration from existing resources
- When importing many resources, let Terraform scaffold starter HCL:
  - `terraform plan -generate-config-out=generated.tf` (TF ≥ 1.5)
  - Review and edit the generated file; it’s a best‑effort proposal and often needs cleanup
- Pair with import blocks for auditable history of what was imported

### 9. Low‑level state operations (use sparingly)
- Force unlock a stuck state lock (only if you know no other run is active):
  - `terraform force-unlock <LOCK_ID>`
- Pull/push state (for emergency inspection or manual conflict resolution):
  - `terraform state pull > state.json`
  - `terraform state push state.json`
- Inspect entries directly:
  - `terraform state list`, `terraform state show <addr>`
  - Helpful before `state mv` / `state rm`

## Quick Commands Reference
- List state: `terraform state list`
- Show address paths: `terraform state show <addr>`
- Import (CLI): `terraform import <addr> <id>`
- Move (CLI): `terraform state mv <from> <to>`
- Forget (CLI): `terraform state rm <addr>`
- Force replace: `terraform apply -replace=<addr>`
- Generate starter config: `terraform plan -generate-config-out=generated.tf`
- Force unlock: `terraform force-unlock <LOCK_ID>`

## Troubleshooting
- “Unsupported block type removed”: upgrade to Terraform ≥ 1.7 or use `state rm`
- Plan wants destroy+create after rename: run `state mv` (or add `moved {}`) first
- Partial replaces leave dependent drift: add `-replace` for dependents, or model dependency correctly
- Import seems to do nothing: remember CLI import writes to state; import block applies on `apply`
- Generated config seems verbose/wrong: treat as a starting point; simplify and align with your standards

## Exercise References
- `exercises/advanced/module-07/47-moved-blocks/` – CLI vs `moved` blocks
- `exercises/advanced/module-07/48-import-block/` – CLI import and `import` block
- `exercises/advanced/module-07/49-removed-block/` – `removed` block (TF ≥ 1.7) and CLI fallback
- `exercises/advanced/module-07/50-taints/` – taint/untaint and modern `-replace`
- `exercises/advanced/module-07/solution/` – consolidated working examples

## Key Takeaways
- Import adds existing resources to state; config should then converge
- Move state before renaming to avoid recreation
- Forget safely with `state rm` (all versions) or `removed` blocks (≥ 1.7)
- Prefer `-replace` over `taint`; be explicit about dependents
- Validate plans carefully when manipulating state; back up state before refactors


