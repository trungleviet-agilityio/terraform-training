import {
  to = aws_iam_role.lambda_execution_role
  id = "manually-created-lambda-role-wqxv3s37" # Should be replaced with your real role name
}

import {
  to = aws_iam_policy.lambda_execution
  id = "arn:aws:iam::057336397237:policy/service-role/AWSLambdaBasicExecutionRole-c85a6277-c978-4194-b549-64f4357be471" # Should be replaced with your real policy name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "assume_lambda_execution_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_execution" {
  statement {
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    actions   = ["logs:CreateLogGroup"]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

resource "aws_iam_policy" "lambda_execution" {
  name   = "AWSLambdaBasicExecutionRole-c85a6277-c978-4194-b549-64f4357be471"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.lambda_execution.json
}

resource "aws_iam_role" "lambda_execution_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_lambda_execution_role.json
  name               = "manually-created-lambda-role-wqxv3s37" # Should be replaced with your real role name
  path               = "/service-role/"
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution.arn
}
