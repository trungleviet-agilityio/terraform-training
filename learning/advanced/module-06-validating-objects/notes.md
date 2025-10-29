# Advanced Module 06 – Validating Objects (Preconditions, Postconditions, and Checks)

## Learning Objectives
- Understand the purpose and timing of preconditions, postconditions, and check assertions
- Write lifecycle validations that prevent invalid applies and catch drift
- Use self‑references correctly in postconditions and (when known) in preconditions
- Apply non‑blocking validations with check blocks for policy visibility
- Predict when validations run in plan vs apply and their impact on downstream resources
- Align validations with the exercises in `exercises/advanced/module-06`

## Session Notes

### 1. Why Object Validation
- **Goal**: Make infrastructure safer and more predictable by validating inputs and resulting state.
- **Three tools**:
  - Preconditions – validate before creation/update if data is known
  - Postconditions – validate after creation/update using the final state
  - Checks – non‑blocking assertions for visibility and auditing

### 2. Preconditions vs Postconditions (When and Why)
- **Precondition**
  - Evaluated as early as possible (during plan if information is already known; otherwise deferred to apply)
  - Prevents invalid operations before they happen
  - Typical uses: CIDR containment, required tags/inputs, cross‑resource sanity checks
- **Postcondition**
  - Evaluated after a change is applied (uses the actual provider‑reported attributes)
  - Detects drift or provider‑side adjustments and enforces the intended outcome
  - Typical uses: instance type correctness, final tags/attributes, attachment results

### 3. Syntax Essentials
- Both are defined inside `lifecycle {}` of a resource or data source.
- They support `condition` (boolean expression) and `error_message`.
- `self` can be used to reference the current resource:
  - In preconditions, values may be unknown at plan and thus the validation may be deferred to apply.
  - In postconditions, `self` refers to the final, provider‑read state after the operation.

### 4. Example – Enforce a Required Tag (Precondition)
```hcl
resource "aws_instance" "project" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = merge(var.common_tags, {
    Name       = "project-server"
    CostCenter = var.cost_center
  })

  lifecycle {
    precondition {
      condition     = contains(keys(self.tags), "CostCenter") && trim(self.tags["CostCenter"]) != ""
      error_message = "All EC2 instances must include a non-empty 'CostCenter' tag before deployment."
    }
  }
}
```

### 5. Example – Verify Final Instance Type (Postcondition)
```hcl
resource "aws_instance" "project" {
  ami           = var.ami
  instance_type = var.instance_type

  lifecycle {
    postcondition {
      condition     = self.instance_type == "t3.micro"
      error_message = "The EC2 instance must be of type 't3.micro' after creation."
    }
  }
}
```

### 6. Example – CIDR Containment (Precondition)
```hcl
resource "aws_subnet" "example" {
  vpc_id     = var.vpc_id
  cidr_block = var.subnet_cidr

  lifecycle {
    precondition {
      condition     = cidr_contains(var.vpc_cidr, var.subnet_cidr)
      error_message = "The subnet CIDR must be contained within the VPC CIDR."
    }
  }
}

locals {
  # Helper implemented with built-in cidr functions
  # Example: cidr_contains("10.0.0.0/16", "10.0.1.0/24") => true
  # Terraform doesn't have a single function; we can check via network/math composition
}
```

### 7. Non‑Blocking Validation with check Blocks
- **Purpose**: Validate and report without halting plan/apply (good for policy and audits).
- **Location**: Top‑level blocks, outside resources.
- **Behavior**: Failing assertions surface as warnings but do not stop the run.

```hcl
check "cost_center_tag_check" {
  assert {
    condition = alltrue([
      for inst in values(aws_instance.project) : contains(keys(inst.tags), "CostCenter")
    ])
    error_message = "One or more managed EC2 instances are missing the 'CostCenter' tag."
  }
}
```

### 8. When Validations Execute (Plan vs Apply)
- Terraform asks during plan: **“Is the information already available?”**
  - **Yes** → Execute validation during plan.
  - **No**  → Defer the validation to apply.
- If a plan‑time validation fails, Terraform exits without entering apply.
- During apply, Terraform loops over changes and executes deferred validations:
  - If a validation fails at step N, Terraform exits and does not apply downstream resources.
  - Prior successful actions are not rolled back automatically; fix the issue and re‑apply.
- Key takeaway: A successful plan does not guarantee validations won’t fail later; some checks require provider‑known values only available during apply.

### Diagram – Validations Across Plan and Apply
```
 +------------+
 |  plan      |
 +------------+
        |
        v
 +----------------------------------+
 | Information already available?   |
 +----------------------------------+
       | Yes                 | No
       v                     v
 +------------------+   +----------------------------------+
 | Validation       |   | Validation deferred until        |
 | executed         |   | the apply phase                  |
 +------------------+   +----------------------------------+
        |
        v
 +---------------------------+
 | Validation successful?    |
 +---------------------------+
       | Yes             | No
       v                 v
   (go to apply)   +----------------------------------------------+
                    | Terraform exits without going into          |
                    | the apply phase                              |
                    +----------------------------------------------+

                 Apply phase (loops until no more changes)
                 +------------+
                 |  apply     |
                 +------------+
                        |
                        v
                 +------------------+
                 | Validation       |
                 | executed         |
                 +------------------+
                        |
                        v
                 +---------------------------+
                 | Validation successful?    |
                 +---------------------------+
                        | Yes            | No
                        v                v
         +---------------------------+   +--------------------------------------+
         | Continue applying next    |   | Terraform exits without applying     |
         | change until none remain  |   | downstream resources                 |
         +---------------------------+   +--------------------------------------+
```
The apply phase executes until there are no more changes to be applied.

### 9. Good Practices
- Use **preconditions** to catch invalid inputs early; keep error messages precise.
- Use **postconditions** for computed/final attributes to guard against drift.
- Reserve **check** for advisory, non‑critical policy checks; don’t use it to block critical constraints.
- Prefer validating **managed resources** (e.g., `values(aws_instance.x)`) over broad data sources that scan the entire account.
- Favor **object inputs** (maps/objects) that make validations simpler and clearer.

### 10. Common Pitfalls
- Relying on check for critical invariants (it won’t stop the run).
- Assuming plan success means validations passed (some are deferred).
- Using lists with `for_each` in checks causing churn; prefer `values()` of resources or maps/sets with stable keys.
- Vague `error_message` texts; always explain expectation and remediation.

## Code Patterns and Snippets

### Multiple Instances with for_each and Validations
```hcl
resource "aws_instance" "project" {
  for_each      = var.instances
  ami           = each.value.ami
  instance_type = each.value.instance_type
  tags          = merge(each.value.tags, { Name = each.key })

  lifecycle {
    precondition {
      condition     = contains(keys(self.tags), "CostCenter")
      error_message = "Instance '${each.key}' must have 'CostCenter' tag."
    }
    postcondition {
      condition     = can(self.id) && length(self.id) > 0
      error_message = "Instance '${each.key}' was not created successfully."
    }
  }
}
```

### Aggregated Policy Check (Non‑Blocking)
```hcl
check "naming_convention" {
  assert {
    condition = alltrue([
      for k, inst in aws_instance.project : startswith(inst.tags["Name"], var.project_prefix)
    ])
    error_message = "All instance names must start with '${var.project_prefix}'."
  }
}
```

## Troubleshooting
- **Validation fails in apply only**: The condition referenced values unknown at plan time; investigate actual provider state (`terraform show`).
- **Unexpected perpetual diffs**: Use `lifecycle.ignore_changes` for attributes managed externally; pair with postconditions if needed.
- **Broad data source checks are slow**: Scope checks to managed resources or filtered data.
- **Partial apply**: Fix the failing condition and re‑apply; Terraform doesn’t auto‑rollback prior successful steps.

## Exercise References
- `exercises/advanced/module-06/44-preconditions/README.md` – writing and testing preconditions
- `exercises/advanced/module-06/45-postconditions/README.md` – enforcing outcomes with postconditions and `self`
- `exercises/advanced/module-06/46-check-blocks/README.md` – advisory validations with `check`
- `exercises/advanced/module-06/solution/` – consolidated working example (`provider.tf`, `networking.tf`, `compute.tf`, `variables.tf`)

## Key Takeaways
- **Preconditions** validate inputs as early as possible; may defer to apply if values are unknown at plan.
- **Postconditions** validate the final, provider‑reported state using `self`.
- **check** blocks surface non‑blocking policy issues and are great for visibility.
- A successful **plan** doesn’t guarantee validations won’t fail during **apply**.
- Use precise error messages and scope checks to Terraform‑managed resources for fast, reliable feedback.


