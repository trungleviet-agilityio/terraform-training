# Managing IAM Users and Roles with Terraform

This project is centered around managing AWS Identity and Access Management (IAM) users and roles using Terraform and YAML. The primary objective is to automate the process of creating users, assigning roles, and ensuring secure role assignment. User information, including usernames and roles, will be stored in a YAML file, while role information will be managed in Terraform. An important aspect of this project is to ensure that roles can only be assumed by the users assigned to them, adding an extra layer of security.

## Project Overview

<img src="assets/proj02-iam-users.png" alt="deploy-vpc-ec2-instance" width="600"/>

## Desired Outcome

1. Store user information (username and their respective roles) in a YAML file.
2. Store role information (role name and their respective policies) in Terraform.
    1. **Hint:** You can use AWS-Managed policies to make your life easier, but if you wish an extra layer of learning and challenge, by all means go ahead and create your own policies!
3. Based on the provided YAML file, create users in the AWS account.
4. Also make sure to create login profiles for the users, so that they can login into the AWS console.
    1. **Security note:** The solution intentionally does not output passwords (they are sensitive). Terraform’s `aws_iam_user_login_profile.password` exists but should not be exposed via outputs. For testing, retrieve initial passwords securely (avoid printing them) and enforce reset on first login if you enable that behavior.
5. Based on the role information stored in Terraform, create the respective roles and attach the correct policies to these roles.
6. Based on the YAML file, link created users to the respective roles they can assume.
7. Ensure that roles can only be assumed by the users that are assigned to those roles.
8. Test everything in the AWS console, it's quite fun!
9. Make sure to delete all the resources at the end of the project!

## Inputs and Structure (as used by the solution)

### YAML schema (`solution/user-roles.yaml`)

```
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

The solution decodes this file with `yamldecode(...)`, builds a map of `username => roles`, and:
- Creates one IAM user per `username`.
- Creates an IAM login profile per user (password not output).
- Creates one IAM role per known role name and restricts `sts:AssumeRole` principals to only the users assigned to that role.

### Roles and AWS‑managed policy mapping (in `solution/roles.tf`)

```
readonly  => [ ReadOnlyAccess ]
admin     => [ AdministratorAccess ]
auditor   => [ SecurityAudit ]
developer => [ AmazonVPCFullAccess, AmazonEC2FullAccess, AmazonRDSFullAccess ]
```

Each role gets its assume role policy generated from the current account ID and the users that reference that role in the YAML file. Managed policies are attached to the role via `aws_iam_role_policy_attachment`.

## How it works (high‑level)

- `users.tf`:
  - Builds `local.users_from_yaml` and `local.users_map`.
  - Creates `aws_iam_user` with `for_each` over usernames.
  - Creates `aws_iam_user_login_profile` for each user (with an ignore_changes lifecycle for sensitive attributes).
- `roles.tf`:
  - Declares a role→policies mapping and flattens it for attachments.
  - Builds an `assume_role_policy` per role that allows only the listed users to assume it.
  - Attaches AWS‑managed policies to each role.

## Run (quick steps)

```
cd exercises/advanced/module-04/solution
terraform init
terraform plan
terraform apply
# Test role assumptions in the AWS console (IAM → Roles → Trust relationships)
terraform destroy
```

## Notes & Best Practices

- Treat generated passwords as **sensitive**. Avoid outputs; prefer secure delivery or console‑driven password reset flows.
- Keep role names in YAML strictly within the allowed set: `readonly`, `developer`, `admin`, `auditor` (as mapped in the solution).
- Prefer AWS‑managed policies for learning; custom policies can be added later for least‑privilege hardening.
