locals {
  users_from_yaml = yamldecode(file("${path.module}/user-roles.yaml")).users
  users_map = {
    for user_config in local.users_from_yaml : user_config.username => user_config.roles
  }

  allowed_roles = toset(keys(local.role_policies))

  invalid_role_pairs = flatten([
    for u in local.users_from_yaml : [
      for r in u.roles : {
        username = u.username
        role     = r
      } if !contains(local.allowed_roles, r)
    ]
  ])
}

locals {
  # Fail fast if any role in YAML is not in the allowed set
  _validate_roles = length(local.invalid_role_pairs) == 0 ? true : (throw("Invalid roles in user-roles.yaml: " || jsonencode(local.invalid_role_pairs)))
}

resource "aws_iam_user" "users" {
  for_each = toset(local.users_from_yaml[*].username)
  name     = each.value
}

resource "aws_iam_user_login_profile" "users" {
  for_each        = aws_iam_user.users
  user            = each.value.name
  password_length = 8

  lifecycle {
    ignore_changes = [
      password_length,
      password_reset_required,
      pgp_key
    ]
  }
}

# This should not be outputted, as it contains sensitive information
# output "passwords" {
#   value = {
#     for user, user_login in aws_iam_user_login_profile.users : user => user_login.password
#   }
# }
