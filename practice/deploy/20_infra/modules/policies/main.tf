# Policies Module
# Creates IAM policies for Terraform operations

# Data source for Terraform State Access Policy
data "aws_iam_policy_document" "terraform_state_access" {
  # S3 bucket access for Terraform state
  statement {
    sid    = "S3StateAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      var.state_bucket_arn,
      "${var.state_bucket_arn}/*"
    ]
  }

  # DynamoDB table access for state locking
  statement {
    sid    = "DynamoDBStateLock"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]

    resources = [
      var.dynamodb_table_arn
    ]
  }
}

# Data source for Terraform Resource Creation Policy
data "aws_iam_policy_document" "terraform_resource_creation" {
  # Lambda permissions
  statement {
    sid    = "LambdaPermissions"
    effect = "Allow"

    actions = [
      "lambda:CreateFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:ListFunctions",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy",
      "lambda:CreateAlias",
      "lambda:UpdateAlias",
      "lambda:DeleteAlias",
      "lambda:ListAliases",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:ListTags"
    ]

    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:*"
    ]
  }

  # API Gateway permissions
  statement {
    sid    = "APIGatewayPermissions"
    effect = "Allow"

    actions = [
      "apigateway:*",
      "execute-api:*"
    ]

    resources = [
      "arn:aws:apigateway:${var.region}::/*"
    ]
  }

  # SQS permissions
  statement {
    sid    = "SQSPermissions"
    effect = "Allow"

    actions = [
      "sqs:CreateQueue",
      "sqs:DeleteQueue",
      "sqs:GetQueueAttributes",
      "sqs:SetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueues",
      "sqs:TagQueue",
      "sqs:UntagQueue",
      "sqs:ListQueueTags"
    ]

    resources = [
      "arn:aws:sqs:${var.region}:${var.account_id}:*"
    ]
  }

  # EventBridge permissions
  statement {
    sid    = "EventBridgePermissions"
    effect = "Allow"

    actions = [
      "events:CreateRule",
      "events:DeleteRule",
      "events:DescribeRule",
      "events:ListRules",
      "events:PutTargets",
      "events:RemoveTargets",
      "events:ListTargetsByRule",
      "events:TagResource",
      "events:UntagResource",
      "events:ListTagsForResource"
    ]

    resources = [
      "arn:aws:events:${var.region}:${var.account_id}:rule/*"
    ]
  }

  # Secrets Manager permissions
  statement {
    sid    = "SecretsManagerPermissions"
    effect = "Allow"

    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:PutSecretValue",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource"
    ]

    resources = [
      "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:*"
    ]
  }

  # KMS permissions
  statement {
    sid    = "KMSPermissions"
    effect = "Allow"

    actions = [
      "kms:CreateKey",
      "kms:CreateAlias",
      "kms:UpdateAlias",
      "kms:DeleteAlias",
      "kms:DescribeKey",
      "kms:ListKeys",
      "kms:ListAliases",
      "kms:EnableKeyRotation",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = [
      "arn:aws:kms:${var.region}:${var.account_id}:key/*",
      "arn:aws:kms:${var.region}:${var.account_id}:alias/*"
    ]
  }

  # CloudWatch Logs permissions
  statement {
    sid    = "CloudWatchLogsPermissions"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "logs:TagLogGroup",
      "logs:UntagLogGroup"
    ]

    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:*"
    ]
  }

  # IAM permissions (limited - for creating service roles)
  statement {
    sid    = "IAMPermissions"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:ListPolicies",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:ListPolicyTags",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:SetDefaultPolicyVersion"
    ]

    resources = [
      "arn:aws:iam::${var.account_id}:role/*",
      "arn:aws:iam::${var.account_id}:policy/*"
    ]
  }

  # PassRole permission (required for Lambda, API Gateway, etc.)
  statement {
    sid    = "PassRolePermissions"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::${var.account_id}:role/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "lambda.amazonaws.com",
        "apigateway.amazonaws.com",
        "events.amazonaws.com"
      ]
    }
  }
}

# Data source for Terraform Plan Policy (read-only resource access)
data "aws_iam_policy_document" "terraform_plan" {
  # Include state access
  source_policy_documents = [
    data.aws_iam_policy_document.terraform_state_access.json
  ]

  # Read-only resource permissions
  statement {
    sid    = "ReadOnlyResourceAccess"
    effect = "Allow"

    actions = [
      "lambda:GetFunction",
      "lambda:ListFunctions",
      "lambda:GetPolicy",
      "lambda:ListAliases",
      "lambda:ListTags",
      "apigateway:GET",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueues",
      "sqs:ListQueueTags",
      "events:DescribeRule",
      "events:ListRules",
      "events:ListTargetsByRule",
      "events:ListTagsForResource",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "kms:DescribeKey",
      "kms:ListKeys",
      "kms:ListAliases",
      "logs:DescribeLogGroups",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:GetPolicy",
      "iam:ListPolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:GetRolePolicy",
      "iam:ListPolicyTags",
      "iam:ListRoleTags"
    ]

    resources = ["*"]
  }
}

# Data source for Terraform Apply Policy (full resource access)
data "aws_iam_policy_document" "terraform_apply" {
  # Include state access and resource creation permissions
  source_policy_documents = [
    data.aws_iam_policy_document.terraform_state_access.json,
    data.aws_iam_policy_document.terraform_resource_creation.json
  ]
}

# Create IAM policies
resource "aws_iam_policy" "terraform_state_access" {
  name        = "${var.policy_name_prefix}-state-access"
  description = "Policy for Terraform state bucket and DynamoDB table access"
  policy      = data.aws_iam_policy_document.terraform_state_access.json

  tags = merge(
    var.tags,
    {
      Name = "${var.policy_name_prefix}-state-access"
    }
  )

  lifecycle {
    precondition {
      condition     = can(regex("^arn:aws:s3:::", var.state_bucket_arn))
      error_message = "State bucket ARN must be a valid S3 bucket ARN format (arn:aws:s3:::bucket-name)."
    }
    precondition {
      condition     = can(regex("^arn:aws:dynamodb:", var.dynamodb_table_arn))
      error_message = "DynamoDB table ARN must be a valid DynamoDB table ARN format (arn:aws:dynamodb:REGION:ACCOUNT:table/NAME)."
    }
    precondition {
      condition     = can(regex("^[0-9]{12}$", var.account_id))
      error_message = "Account ID must be a 12-digit number."
    }
    precondition {
      condition     = length(var.region) > 0
      error_message = "Region must be a non-empty string."
    }
  }
}

resource "aws_iam_policy" "terraform_resource_creation" {
  name        = "${var.policy_name_prefix}-resource-creation"
  description = "Policy for Terraform resource creation (Lambda, API Gateway, SQS, EventBridge, Secrets Manager, KMS, CloudWatch Logs, IAM)"
  policy      = data.aws_iam_policy_document.terraform_resource_creation.json

  tags = merge(
    var.tags,
    {
      Name = "${var.policy_name_prefix}-resource-creation"
    }
  )

  lifecycle {
    precondition {
      condition     = can(regex("^[0-9]{12}$", var.account_id))
      error_message = "Account ID must be a 12-digit number."
    }
    precondition {
      condition     = length(var.region) > 0
      error_message = "Region must be a non-empty string."
    }
  }
}

resource "aws_iam_policy" "terraform_plan" {
  name        = "${var.policy_name_prefix}-plan"
  description = "Policy for Terraform plan operations (read-only resource access + state access)"
  policy      = data.aws_iam_policy_document.terraform_plan.json

  tags = merge(
    var.tags,
    {
      Name = "${var.policy_name_prefix}-plan"
    }
  )

  lifecycle {
    precondition {
      condition     = can(regex("^arn:aws:s3:::", var.state_bucket_arn))
      error_message = "State bucket ARN must be a valid S3 bucket ARN format (arn:aws:s3:::bucket-name)."
    }
    precondition {
      condition     = can(regex("^arn:aws:dynamodb:", var.dynamodb_table_arn))
      error_message = "DynamoDB table ARN must be a valid DynamoDB table ARN format (arn:aws:dynamodb:REGION:ACCOUNT:table/NAME)."
    }
  }
}

resource "aws_iam_policy" "terraform_apply" {
  name        = "${var.policy_name_prefix}-apply"
  description = "Policy for Terraform apply operations (full resource access + state access)"
  policy      = data.aws_iam_policy_document.terraform_apply.json

  tags = merge(
    var.tags,
    {
      Name = "${var.policy_name_prefix}-apply"
    }
  )

  lifecycle {
    precondition {
      condition     = can(regex("^arn:aws:s3:::", var.state_bucket_arn))
      error_message = "State bucket ARN must be a valid S3 bucket ARN format (arn:aws:s3:::bucket-name)."
    }
    precondition {
      condition     = can(regex("^arn:aws:dynamodb:", var.dynamodb_table_arn))
      error_message = "DynamoDB table ARN must be a valid DynamoDB table ARN format (arn:aws:dynamodb:REGION:ACCOUNT:table/NAME)."
    }
    precondition {
      condition     = can(regex("^[0-9]{12}$", var.account_id))
      error_message = "Account ID must be a 12-digit number."
    }
    precondition {
      condition     = length(var.region) > 0
      error_message = "Region must be a non-empty string."
    }
  }
}
