# Advanced Module 04 – Managing IAM Users and Roles with Terraform + YAML

## Learning Objectives
- Understand IAM users, roles, managed policies, and trust policies
- Model IAM data in YAML and transform it in Terraform with `yamldecode`
- Create users and roles dynamically with `for_each`
- Securely restrict who can assume roles via `sts:AssumeRole`
- Attach AWS‑managed policies to roles programmatically
- Enforce security best practices (sensitive data, least privilege, MFA)
- Validate YAML inputs to prevent configuration drift or mistakes

## Core Concepts

### IAM Users vs IAM Roles
- **User**: Long‑term identity (console/programmatic) – should have minimal permissions
- **Role**: Permission set assumed by trusted principals; provides temporary credentials
- **Trust Policy**: Defines who can assume the role (the “who”)
- **Permissions Policy**: Defines what the role can do (the “what”)

### Why YAML for IAM?
- **Readable** for security/ops teams
- **Machine‑parseable** for Terraform
- **Extensible** (add fields like tags, MFA, department)

## Data Modeling (YAML)

Minimal schema used by the solution (`solution/user-roles.yaml`):
```yaml
# users = {
#   username = string
#   roles    = (readonly | developer | admin | auditor)[]
# }[]

users:
  - username: john
    roles: [readonly, developer]
  - username: jane
    roles: [admin, auditor]
  - username: lauro
    roles: [readonly]
```

Allowed roles and managed policy mapping (defined in Terraform):
```hcl
readonly  => [ "ReadOnlyAccess" ]
admin     => [ "AdministratorAccess" ]
auditor   => [ "SecurityAudit" ]
developer => [ "AmazonVPCFullAccess", "AmazonEC2FullAccess", "AmazonRDSFullAccess" ]
```

## Terraform Implementation

### 1) Decode YAML and shape data
```hcl
locals {
  users_from_yaml = yamldecode(file("${path.module}/user-roles.yaml")).users
  users_map = {
    for user in local.users_from_yaml : user.username => user.roles
  }
}
```

### 2) Validation: only allowed roles from mapping
Expose canonical mapping in `roles.tf` as `local.role_policies` and validate in `users.tf`:
```hcl
locals {
  allowed_roles = toset(keys(local.role_policies))
  invalid_role_pairs = flatten([
    for u in local.users_from_yaml : [
      for r in u.roles : { username = u.username, role = r }
      if !contains(local.allowed_roles, r)
    ]
  ])
  _validate_roles = length(local.invalid_role_pairs) == 0
    ? true
    : (throw("Invalid roles in user-roles.yaml: " || jsonencode(local.invalid_role_pairs)))
}
```
Outcome: plan fails early with a clear error if YAML includes unknown roles.

### 3) Create users (and console login profiles)
```hcl
resource "aws_iam_user" "users" {
  for_each = toset(local.users_from_yaml[*].username)
  name     = each.value
}

resource "aws_iam_user_login_profile" "users" {
  for_each        = aws_iam_user.users
  user            = each.value.name
  password_length = 8

  lifecycle { # avoid perpetual diffs on sensitive fields
    ignore_changes = [ password_length, password_reset_required, pgp_key ]
  }
}

# Never output passwords – keep them sensitive
```

### 4) Create roles and restrict trust to assigned users
```hcl
locals {
  role_policies = { /* mapping shown above */ }
  role_policies_list = flatten([
    for role, policies in local.role_policies : [
      for policy in policies : { role = role, policy = policy }
    ]
  ])
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  for_each = toset(keys(local.role_policies))
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [
        for username in keys(aws_iam_user.users) :
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${username}"
        if contains(local.users_map[username], each.value)
      ]
    }
  }
}

resource "aws_iam_role" "roles" {
  for_each = toset(keys(local.role_policies))
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[each.value].json
}
```

### 5) Attach AWS‑managed policies per role
```hcl
data "aws_iam_policy" "managed_policies" {
  for_each = toset(local.role_policies_list[*].policy)
  arn      = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_role_policy_attachment" "role_policy_attachments" {
  count      = length(local.role_policies_list)
  role       = aws_iam_role.roles[ local.role_policies_list[count.index].role ].name
  policy_arn = data.aws_iam_policy.managed_policies[ local.role_policies_list[count.index].policy ].arn
}
```

## Security Best Practices
- **Do not output passwords or access keys**; state files can store secrets.
- Prefer **least privilege** policies; only elevate via role assumption.
- Use **MFA** for role assumption (configure condition keys in trust policy if required).
- Keep the **allowed roles list** centralized; validate inputs early (as above).
- Prefer **AWS‑managed policies** for learning; evolve to custom, least‑privilege policies in production.

## Run (solution)
```bash
cd exercises/advanced/module-04/solution
terraform init
terraform plan
terraform apply
# Verify: IAM → Users / Roles (Trust relationships)
terraform destroy
```

## Troubleshooting
- **Invalid roles in YAML**: validation will list `{ username, role }` pairs to fix.
- **Trust doesn’t include a user**: verify the username in YAML matches IAM user name exactly.
- **Policy attach fails**: check managed policy names in `role_policies` mapping.

## Exercise Reference
- `exercises/advanced/module-04/project-02-iam-users/README.md`
- `exercises/advanced/module-04/solution/` (provider.tf, users.tf, roles.tf, user-roles.yaml)

## Key Takeaways
- YAML holds **data**; Terraform holds **logic** – clean separation of concerns
- Use `yamldecode`, `for_each`, nested `for` + `flatten` to transform data
- Lock down `sts:AssumeRole` trust policies to **intended principals only**
- Treat credentials as **sensitive**; use secure delivery/reset flows
- Validate inputs to keep the system safe, predictable, and auditable
