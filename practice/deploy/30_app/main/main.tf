# Get the AWS account ID and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# App workloads (API Lambda, SQS worker, cron producer) will be implemented in a later task.
