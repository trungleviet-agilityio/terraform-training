# Data source for Lambda execution trust policy
data "aws_iam_policy_document" "lambda_assume_role" {
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
  name               = "${var.project_name}-${var.environment}-api-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name   = "${var.project_name}-${var.environment}-api-lambda-role"
      Purpose = "Lambda Execution Role - API Server"
    }
  )
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "api_lambda_basic" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM role for Cron Lambda function
resource "aws_iam_role" "cron_lambda_role" {
  name               = "${var.project_name}-${var.environment}-cron-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name   = "${var.project_name}-${var.environment}-cron-lambda-role"
      Purpose = "Lambda Execution Role - Cron Server"
    }
  )
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "cron_lambda_basic" {
  role       = aws_iam_role.cron_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM role for Worker Lambda function
resource "aws_iam_role" "worker_lambda_role" {
  name               = "${var.project_name}-${var.environment}-worker-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name   = "${var.project_name}-${var.environment}-worker-lambda-role"
      Purpose = "Lambda Execution Role - Worker"
    }
  )
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "worker_lambda_basic" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Additional policy for SQS worker to receive messages
data "aws_iam_policy_document" "sqs_worker_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [var.sqs_queue_arn]
  }
}

resource "aws_iam_role_policy" "worker_sqs_policy" {
  name   = "${var.project_name}-${var.environment}-worker-sqs-policy"
  role   = aws_iam_role.worker_lambda_role.id
  policy = data.aws_iam_policy_document.sqs_worker_policy.json
}

# DynamoDB policy document for Lambda functions
data "aws_iam_policy_document" "dynamodb_policy" {
  count = var.enable_dynamodb_access && length(var.dynamodb_table_arns) > 0 ? 1 : 0

  statement {
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

# DynamoDB policy for API Lambda
resource "aws_iam_role_policy" "api_dynamodb_policy" {
  count  = var.enable_dynamodb_access && length(var.dynamodb_table_arns) > 0 ? 1 : 0
  name   = "${var.project_name}-${var.environment}-api-dynamodb-policy"
  role   = aws_iam_role.api_lambda_role.id
  policy = data.aws_iam_policy_document.dynamodb_policy[0].json
}

# DynamoDB policy for Cron Lambda
resource "aws_iam_role_policy" "cron_dynamodb_policy" {
  count  = var.enable_dynamodb_access && length(var.dynamodb_table_arns) > 0 ? 1 : 0
  name   = "${var.project_name}-${var.environment}-cron-dynamodb-policy"
  role   = aws_iam_role.cron_lambda_role.id
  policy = data.aws_iam_policy_document.dynamodb_policy[0].json
}

# DynamoDB policy for Worker Lambda
resource "aws_iam_role_policy" "worker_dynamodb_policy" {
  count  = var.enable_dynamodb_access && length(var.dynamodb_table_arns) > 0 ? 1 : 0
  name   = "${var.project_name}-${var.environment}-worker-dynamodb-policy"
  role   = aws_iam_role.worker_lambda_role.id
  policy = data.aws_iam_policy_document.dynamodb_policy[0].json
}
