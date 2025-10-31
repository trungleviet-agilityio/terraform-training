# Get the AWS account ID and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Platform services (API Gateway, SQS, EventBridge) will be implemented in a later task.
