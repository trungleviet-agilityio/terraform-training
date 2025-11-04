# Roles Module
# Creates IAM roles with trust policies for GitHub Actions

# Data source for GitHub Actions trust policy
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # If allowed_branches is provided, restrict to those branches; otherwise allow all branches
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = var.allowed_branches != null && length(coalesce(var.allowed_branches, [])) > 0 ? [
        for branch in coalesce(var.allowed_branches, []) : "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/${branch}"
      ] : ["repo:${var.github_organization}/${var.github_repository}:*"]
    }
  }
}

# Terraform Plan Role (read-only permissions)
resource "aws_iam_role" "terraform_plan" {
  count              = var.create_terraform_plan_role ? 1 : 0
  name               = var.terraform_plan_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = merge(
    var.tags,
    {
      Name = var.terraform_plan_role_name
    }
  )

  lifecycle {
    precondition {
      condition     = can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/", var.oidc_provider_arn))
      error_message = "OIDC provider ARN must be a valid IAM OIDC provider ARN format (arn:aws:iam::ACCOUNT:oidc-provider/...)."
    }
    precondition {
      condition     = can(regex("^arn:aws:iam::[0-9]{12}:policy/", var.terraform_plan_policy_arn))
      error_message = "Terraform plan policy ARN must be a valid IAM policy ARN format (arn:aws:iam::ACCOUNT:policy/...)."
    }
    precondition {
      condition     = length(var.github_organization) > 0
      error_message = "GitHub organization must be a non-empty string."
    }
    precondition {
      condition     = length(var.github_repository) > 0
      error_message = "GitHub repository must be a non-empty string."
    }
  }
}

# Attach Terraform Plan Policy to Plan Role
resource "aws_iam_role_policy_attachment" "terraform_plan" {
  count      = var.create_terraform_plan_role ? 1 : 0
  role       = aws_iam_role.terraform_plan[0].name
  policy_arn = var.terraform_plan_policy_arn
}

# Terraform Apply Role (full permissions)
resource "aws_iam_role" "terraform_apply" {
  count              = var.create_terraform_apply_role ? 1 : 0
  name               = var.terraform_apply_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = merge(
    var.tags,
    {
      Name = var.terraform_apply_role_name
    }
  )

  lifecycle {
    precondition {
      condition     = can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/", var.oidc_provider_arn))
      error_message = "OIDC provider ARN must be a valid IAM OIDC provider ARN format (arn:aws:iam::ACCOUNT:oidc-provider/...)."
    }
    precondition {
      condition     = can(regex("^arn:aws:iam::[0-9]{12}:policy/", var.terraform_apply_policy_arn))
      error_message = "Terraform apply policy ARN must be a valid IAM policy ARN format (arn:aws:iam::ACCOUNT:policy/...)."
    }
    precondition {
      condition     = length(var.github_organization) > 0
      error_message = "GitHub organization must be a non-empty string."
    }
    precondition {
      condition     = length(var.github_repository) > 0
      error_message = "GitHub repository must be a non-empty string."
    }
  }
}

# Attach Terraform Apply Policy to Apply Role
resource "aws_iam_role_policy_attachment" "terraform_apply" {
  count      = var.create_terraform_apply_role ? 1 : 0
  role       = aws_iam_role.terraform_apply[0].name
  policy_arn = var.terraform_apply_policy_arn
}
