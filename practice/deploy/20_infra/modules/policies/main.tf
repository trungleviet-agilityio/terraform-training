# Policies Module
# Creates IAM policies for Terraform operations

# ============================================================================
# Locals - Reusable validation conditions
# ============================================================================

locals {
  # Common count logic for GitHub Actions policies
  create_github_actions_policies = var.policy_name_prefix != ""

  # Validation conditions (reusable across resources)
  validate_state_bucket_arn   = local.create_github_actions_policies ? can(regex("^arn:aws:s3:::", var.state_bucket_arn)) : true
  validate_dynamodb_table_arn = local.create_github_actions_policies ? can(regex("^arn:aws:dynamodb:", var.dynamodb_table_arn)) : true
  validate_account_id         = local.create_github_actions_policies ? can(regex("^[0-9]{12}$", var.account_id)) : true
  validate_region             = local.create_github_actions_policies ? length(var.region) > 0 : true

  # Secrets Manager resource pattern - use /practice/* pattern for better least privilege
  secrets_manager_resources = var.project_name != "" ? [
    "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.project_name}-*",
    "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/practice/*"
  ] : [
    "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/practice/*"
  ]
}

# ============================================================================
# Policy Documents - Terraform Plan Policy (read-only + state access)
# ============================================================================

data "aws_iam_policy_document" "terraform_plan" {
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

  # Read-only resource permissions
  statement {
    sid    = "ReadOnlyResourceAccess"
    effect = "Allow"

    actions = [
      # Lambda permissions
      "lambda:GetFunction",
      "lambda:ListFunctions",
      "lambda:GetPolicy",
      "lambda:ListAliases",
      "lambda:ListTags",

      # API Gateway v2 permissions
      "apigatewayv2:GetApi",
      "apigatewayv2:GetStage",
      "apigatewayv2:GetDomainName",
      "apigatewayv2:GetIntegration",
      "apigatewayv2:GetRoute",

      # SQS permissions
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueues",
      "sqs:ListQueueTags",

      # EventBridge Scheduler permissions
      "scheduler:GetSchedule",
      "scheduler:ListSchedules",
      "scheduler:ListTagsForResource",

      # DynamoDB permissions
      "dynamodb:DescribeTable",
      "dynamodb:ListTables",
      "dynamodb:ListTagsOfResource",

      # Route53 permissions
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",

      # ACM permissions
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",

      # Secrets Manager permissions (read-only)
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",

      # KMS permissions
      "kms:DescribeKey",
      "kms:ListKeys",
      "kms:ListAliases",

      # CloudWatch Logs permissions
      "logs:DescribeLogGroups",

      # IAM permissions (read-only)
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

    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:*",
      "arn:aws:apigateway:${var.region}::/*",
      "arn:aws:sqs:${var.region}:${var.account_id}:*",
      "arn:aws:scheduler:${var.region}:${var.account_id}:schedule/*",
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/*",
      "arn:aws:route53:::hostedzone/*",
      "arn:aws:route53:::change/*",
      "arn:aws:acm:${var.region}:${var.account_id}:certificate/*",
      "arn:aws:acm:us-east-1:${var.account_id}:certificate/*",
      "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:*",
      "arn:aws:kms:${var.region}:${var.account_id}:key/*",
      "arn:aws:kms:${var.region}:${var.account_id}:alias/*",
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:*",
      "arn:aws:iam::${var.account_id}:role/*",
      "arn:aws:iam::${var.account_id}:policy/*"
    ]
  }
}

# ============================================================================
# Policy Documents - Terraform Apply Policy (full access + state access)
# ============================================================================

data "aws_iam_policy_document" "terraform_apply" {
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
      # API Management
      "apigatewayv2:CreateApi",
      "apigatewayv2:DeleteApi",
      "apigatewayv2:GetApi",
      "apigatewayv2:UpdateApi",
      "apigatewayv2:ListApis",

      # Stage Management
      "apigatewayv2:CreateStage",
      "apigatewayv2:DeleteStage",
      "apigatewayv2:GetStage",
      "apigatewayv2:UpdateStage",
      "apigatewayv2:GetStages",

      # Custom Domain Management
      "apigatewayv2:CreateDomainName",
      "apigatewayv2:DeleteDomainName",
      "apigatewayv2:GetDomainName",
      "apigatewayv2:UpdateDomainName",
      "apigatewayv2:GetDomainNames",

      # API Mapping
      "apigatewayv2:CreateApiMapping",
      "apigatewayv2:DeleteApiMapping",
      "apigatewayv2:GetApiMapping",
      "apigatewayv2:GetApiMappings",
      "apigatewayv2:UpdateApiMapping",

      # Integration Management
      "apigatewayv2:CreateIntegration",
      "apigatewayv2:DeleteIntegration",
      "apigatewayv2:GetIntegration",
      "apigatewayv2:UpdateIntegration",
      "apigatewayv2:GetIntegrations",

      # Route Management
      "apigatewayv2:CreateRoute",
      "apigatewayv2:DeleteRoute",
      "apigatewayv2:GetRoute",
      "apigatewayv2:UpdateRoute",
      "apigatewayv2:GetRoutes",

      # Tagging
      "apigatewayv2:TagResource",
      "apigatewayv2:UntagResource",
      "apigatewayv2:GetTags"
    ]

    resources = [
      "arn:aws:apigateway:${var.region}::/*"
    ]
  }

  # DynamoDB permissions (for application tables)
  statement {
    sid    = "DynamoDBPermissions"
    effect = "Allow"

    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:UpdateTable",
      "dynamodb:ListTables",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:ListTagsOfResource"
    ]

    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/*"
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

  # EventBridge Scheduler permissions (for cron schedules)
  statement {
    sid    = "EventBridgeSchedulerPermissions"
    effect = "Allow"

    actions = [
      "scheduler:CreateSchedule",
      "scheduler:DeleteSchedule",
      "scheduler:GetSchedule",
      "scheduler:UpdateSchedule",
      "scheduler:ListSchedules",
      "scheduler:TagResource",
      "scheduler:UntagResource",
      "scheduler:ListTagsForResource"
    ]

    resources = [
      "arn:aws:scheduler:${var.region}:${var.account_id}:schedule/*"
    ]
  }

  # Route53 permissions (for DNS management)
  statement {
    sid    = "Route53Permissions"
    effect = "Allow"

    actions = [
      "route53:CreateHostedZone",
      "route53:DeleteHostedZone",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetChange",
      "route53:ListTagsForResource",
      "route53:ChangeTagsForResource"
    ]

    resources = [
      "arn:aws:route53:::hostedzone/*",
      "arn:aws:route53:::change/*"
    ]
  }

  # ACM permissions (for SSL/TLS certificates)
  statement {
    sid    = "ACMPermissions"
    effect = "Allow"

    actions = [
      "acm:RequestCertificate",
      "acm:DeleteCertificate",
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:AddTagsToCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:ListTagsForCertificate"
    ]

    resources = [
      "arn:aws:acm:${var.region}:${var.account_id}:certificate/*",
      "arn:aws:acm:us-east-1:${var.account_id}:certificate/*" # API Gateway requires certs in us-east-1
    ]
  }

  # Secrets Manager permissions (improved least privilege)
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

    resources = local.secrets_manager_resources

    # Restrict to secrets managed by Terraform
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  # KMS permissions (for key management, not key creation)
  statement {
    sid    = "KMSPermissions"
    effect = "Allow"

    actions = [
      # Key management (for existing keys)
      "kms:DescribeKey",
      "kms:ListKeys",
      "kms:ListAliases",
      "kms:EnableKeyRotation",
      "kms:TagResource",
      "kms:UntagResource",

      # Alias management
      "kms:CreateAlias",
      "kms:UpdateAlias",
      "kms:DeleteAlias"
      # Note: kms:CreateKey removed - keys should be created separately with admin permissions
      # Note: kms:ScheduleKeyDeletion removed - too dangerous for Terraform automation
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

  # IAM permissions (for creating service roles and policies)
  # Restricted to project-managed resources when project_name is provided
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

    # Restrict to project-managed resources when project_name is provided
    dynamic "condition" {
      for_each = var.project_name != "" ? [1] : []
      content {
        test     = "StringLike"
        variable = "iam:ResourceTag/Project"
        values   = [var.project_name]
      }
    }
  }

  # PassRole permission (required for Lambda, API Gateway, EventBridge Scheduler)
  # Restricted to roles matching project naming pattern when project_name is provided
  statement {
    sid    = "PassRolePermissions"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = var.project_name != "" ? [
      "arn:aws:iam::${var.account_id}:role/${var.project_name}-*"
    ] : [
      "arn:aws:iam::${var.account_id}:role/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "lambda.amazonaws.com",
        "apigateway.amazonaws.com",
        "scheduler.amazonaws.com"
      ]
    }
  }
}

# ============================================================================
# IAM Policies - GitHub Actions Policies
# ============================================================================

resource "aws_iam_policy" "terraform_plan" {
  count = local.create_github_actions_policies ? 1 : 0

  name        = "${var.policy_name_prefix}-plan"
  description = "Policy for Terraform plan operations (read-only resource access + state access)"
  policy      = data.aws_iam_policy_document.terraform_plan.json
  tags        = merge(var.tags, { Name = "${var.policy_name_prefix}-plan" })

  lifecycle {
    precondition {
      condition     = local.validate_state_bucket_arn
      error_message = "State bucket ARN must be a valid S3 bucket ARN format (arn:aws:s3:::bucket-name)."
    }
    precondition {
      condition     = local.validate_dynamodb_table_arn
      error_message = "DynamoDB table ARN must be a valid DynamoDB table ARN format (arn:aws:dynamodb:REGION:ACCOUNT:table/NAME)."
    }
    precondition {
      condition     = local.validate_account_id
      error_message = "Account ID must be a 12-digit number."
    }
    precondition {
      condition     = local.validate_region
      error_message = "Region must be a non-empty string."
    }
  }
}

resource "aws_iam_policy" "terraform_apply" {
  count = local.create_github_actions_policies ? 1 : 0

  name        = "${var.policy_name_prefix}-apply"
  description = "Policy for Terraform apply operations (full resource access + state access)"
  policy      = data.aws_iam_policy_document.terraform_apply.json
  tags        = merge(var.tags, { Name = "${var.policy_name_prefix}-apply" })

  lifecycle {
    precondition {
      condition     = local.validate_state_bucket_arn
      error_message = "State bucket ARN must be a valid S3 bucket ARN format (arn:aws:s3:::bucket-name)."
    }
    precondition {
      condition     = local.validate_dynamodb_table_arn
      error_message = "DynamoDB table ARN must be a valid DynamoDB table ARN format (arn:aws:dynamodb:REGION:ACCOUNT:table/NAME)."
    }
    precondition {
      condition     = local.validate_account_id
      error_message = "Account ID must be a 12-digit number."
    }
    precondition {
      condition     = local.validate_region
      error_message = "Region must be a non-empty string."
    }
  }
}

# ============================================================================
# Policy Documents - Lambda Policies
# ============================================================================

# Policy document for DynamoDB access (for all Lambda functions)
data "aws_iam_policy_document" "lambda_dynamodb_access" {
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem"
    ]

    resources = var.dynamodb_table_arns
  }
}

# Policy document for SQS access (for worker Lambda function)
data "aws_iam_policy_document" "lambda_sqs_access" {
  statement {
    sid    = "SQSAccess"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [var.sqs_queue_arn]
  }
}

# ============================================================================
# IAM Policies - Lambda Policies
# ============================================================================

# Policy for DynamoDB access (for all Lambda functions)
resource "aws_iam_policy" "lambda_dynamodb_access" {
  count = length(var.dynamodb_table_arns) > 0 ? 1 : 0

  name        = "${var.project_name}-${var.environment}-lambda-dynamodb-access"
  description = "Policy for Lambda functions to access DynamoDB tables"
  policy      = data.aws_iam_policy_document.lambda_dynamodb_access.json
  tags        = var.tags
}

# Policy for SQS access (for worker Lambda function)
resource "aws_iam_policy" "lambda_sqs_access" {
  count = var.enable_sqs_policy ? 1 : 0

  name        = "${var.project_name}-${var.environment}-lambda-sqs-access"
  description = "Policy for Lambda functions to access SQS queue"
  policy      = data.aws_iam_policy_document.lambda_sqs_access.json
  tags        = var.tags
}
