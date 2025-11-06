# Get AWS account ID for constructing bucket name
data "aws_caller_identity" "current" {}

# Get remote state from 20_infra layer
data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket  = "tt-practice-tf-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key     = "infra/terraform.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

# Import the main module
module "main" {
  source = "../../main"

  project_name        = var.project_name
  environment         = var.environment
  deploy_mode         = var.deploy_mode
  sqs_queue_arn       = try(data.terraform_remote_state.infra.outputs.sqs_queue_arn, "")
  dynamodb_table_arns = try(values(data.terraform_remote_state.infra.outputs.dynamodb_table_arns), [])
}
