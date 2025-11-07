# Get AWS account ID for constructing bucket name
data "aws_caller_identity" "current" {}

# Get remote state from 10_core layer
data "terraform_remote_state" "core" {
  backend = "s3"

  config = {
    bucket  = "tt-practice-tf-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key     = "core/terraform.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

# Import the main module
module "main" {
  source = "../../main"

  project_name       = var.project_name
  environment        = var.environment
  github_oidc_config = var.github_oidc_config
  dynamodb_tables    = var.dynamodb_tables

  # Custom Domain Configuration (optional, from 10_core DNS module)
  # Only configured if DNS certificate exists in 10_core remote state
  custom_domain_config = try(
    data.terraform_remote_state.core.outputs.dns_certificate_arn != null && data.terraform_remote_state.core.outputs.dns_hosted_zone_id != null ? {
      certificate_arn = data.terraform_remote_state.core.outputs.dns_certificate_arn
      domain_name     = "api.${data.terraform_remote_state.core.outputs.dns_hosted_zone_name}"
      hosted_zone_id  = data.terraform_remote_state.core.outputs.dns_hosted_zone_id
    } : null,
    null
  )

  backend_config = {
    bucket_arn = data.terraform_remote_state.core.outputs.state_backend_bucket_arn
    table_arn  = data.terraform_remote_state.core.outputs.state_backend_dynamodb_table_arn
    account_id = data.terraform_remote_state.core.outputs.account_id
  }
}
