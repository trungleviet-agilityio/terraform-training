# IAM Users & Roles – Solution (Quick Reference)

## What this solution does
- Reads users and role assignments from `user-roles.yaml`.
- Creates one IAM user per `username`.
- Creates an IAM login profile per user (initial password is sensitive – not output).
- Creates one IAM role per known role name and restricts `sts:AssumeRole` to the users assigned to that role.
- Attaches AWS‑managed policies per role mapping.

## Files
- `provider.tf`: AWS provider setup
- `users.tf`: YAML decode, IAM users, login profiles
- `roles.tf`: Role→policies mapping, roles, trust policies, policy attachments
- `user-roles.yaml`: Input file with users and roles

## Allowed roles and attached policies
- `readonly`  → ReadOnlyAccess
- `admin`     → AdministratorAccess
- `auditor`   → SecurityAudit
- `developer` → AmazonVPCFullAccess, AmazonEC2FullAccess, AmazonRDSFullAccess

## Run
```bash
cd exercises/advanced/module-04/solution
terraform init
terraform plan
terraform apply
# Verify in AWS Console → IAM → Users / Roles (Trust relationships)
terraform destroy
```

## Notes
- Do NOT output passwords from `aws_iam_user_login_profile` – treat as sensitive.
- YAML roles must be within the allowed set above; otherwise, validation will fail (see roles validation in code).
