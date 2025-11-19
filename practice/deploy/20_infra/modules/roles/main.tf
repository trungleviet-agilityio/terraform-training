# Roles Module
# Creates IAM roles with trust policies for GitHub Actions

# Data source for GitHub Actions trust policy
data "aws_iam_policy_document" "github_actions_trust" {
  count = (var.create_terraform_plan_role || var.create_terraform_apply_role) ? 1 : 0

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
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust[0].json

  tags = merge(
    var.tags,
    {
      Name = var.terraform_plan_role_name
    }
  )

  lifecycle {
    precondition {
      condition     = !var.create_terraform_plan_role || can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/", var.oidc_provider_arn))
      error_message = "OIDC provider ARN must be a valid IAM OIDC provider ARN format (arn:aws:iam::ACCOUNT:oidc-provider/...)."
    }
    precondition {
      condition     = !var.create_terraform_plan_role || can(regex("^arn:aws:iam::[0-9]{12}:policy/", var.terraform_plan_policy_arn))
      error_message = "Terraform plan policy ARN must be a valid IAM policy ARN format (arn:aws:iam::ACCOUNT:policy/...)."
    }
    precondition {
      condition     = !var.create_terraform_plan_role || length(var.github_organization) > 0
      error_message = "GitHub organization must be a non-empty string."
    }
    precondition {
      condition     = !var.create_terraform_plan_role || length(var.github_repository) > 0
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
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust[0].json

  tags = merge(
    var.tags,
    {
      Name = var.terraform_apply_role_name
    }
  )

  lifecycle {
    precondition {
      condition     = !var.create_terraform_apply_role || can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/", var.oidc_provider_arn))
      error_message = "OIDC provider ARN must be a valid IAM OIDC provider ARN format (arn:aws:iam::ACCOUNT:oidc-provider/...)."
    }
    precondition {
      condition     = !var.create_terraform_apply_role || can(regex("^arn:aws:iam::[0-9]{12}:policy/", var.terraform_apply_policy_arn))
      error_message = "Terraform apply policy ARN must be a valid IAM policy ARN format (arn:aws:iam::ACCOUNT:policy/...)."
    }
    precondition {
      condition     = !var.create_terraform_apply_role || length(var.github_organization) > 0
      error_message = "GitHub organization must be a non-empty string."
    }
    precondition {
      condition     = !var.create_terraform_apply_role || length(var.github_repository) > 0
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

# ============================================================================
# Lambda Roles (for Lambda function execution)
# ============================================================================

# Data source for Lambda execution trust policy
data "aws_iam_policy_document" "lambda_assume_role" {
  count = var.create_lambda_roles ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM role for API Lambda function
resource "aws_iam_role" "api_lambda_role" {
  count = var.create_lambda_roles ? 1 : 0

  name               = "${var.project_name}-${var.environment}-api-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-api-lambda-role"
      Purpose = "Lambda Execution Role - API Server"
    }
  )
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "api_lambda_basic" {
  count = var.create_lambda_roles ? 1 : 0

  role       = aws_iam_role.api_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach DynamoDB policy if it exists
resource "aws_iam_role_policy_attachment" "api_lambda_dynamodb" {
  count = var.create_lambda_roles && var.enable_dynamodb_policy ? 1 : 0

  role       = aws_iam_role.api_lambda_role[0].name
  policy_arn = var.lambda_policies.lambda_dynamodb_access_policy_arn
}

# IAM role for Cron Lambda function
resource "aws_iam_role" "cron_lambda_role" {
  count = var.create_lambda_roles ? 1 : 0

  name               = "${var.project_name}-${var.environment}-cron-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-cron-lambda-role"
      Purpose = "Lambda Execution Role - Cron Server"
    }
  )
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "cron_lambda_basic" {
  count = var.create_lambda_roles ? 1 : 0

  role       = aws_iam_role.cron_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach DynamoDB policy if it exists
resource "aws_iam_role_policy_attachment" "cron_lambda_dynamodb" {
  count = var.create_lambda_roles && var.enable_dynamodb_policy ? 1 : 0

  role       = aws_iam_role.cron_lambda_role[0].name
  policy_arn = var.lambda_policies.lambda_dynamodb_access_policy_arn
}

# IAM role for Worker Lambda function
resource "aws_iam_role" "worker_lambda_role" {
  count = var.create_lambda_roles ? 1 : 0

  name               = "${var.project_name}-${var.environment}-worker-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-worker-lambda-role"
      Purpose = "Lambda Execution Role - Worker"
    }
  )
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "worker_lambda_basic" {
  count = var.create_lambda_roles ? 1 : 0

  role       = aws_iam_role.worker_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach DynamoDB policy if it exists
resource "aws_iam_role_policy_attachment" "worker_lambda_dynamodb" {
  count = var.create_lambda_roles && var.enable_dynamodb_policy ? 1 : 0

  role       = aws_iam_role.worker_lambda_role[0].name
  policy_arn = var.lambda_policies.lambda_dynamodb_access_policy_arn
}

# Attach SQS policy if it exists (worker Lambda only)
resource "aws_iam_role_policy_attachment" "worker_lambda_sqs" {
  count = var.create_lambda_roles && var.enable_sqs_policy ? 1 : 0

  role       = aws_iam_role.worker_lambda_role[0].name
  policy_arn = var.lambda_policies.lambda_sqs_access_policy_arn
}
