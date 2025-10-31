# Import the main module
module "main" {
  source = "../../main"

  project_name          = var.project_name
  environment           = var.environment
  log_retention_in_days = var.log_retention_in_days
  create_kms            = var.create_kms ## Set to true to create a KMS CMK for encryption of logs or other resources
  kms_alias             = var.kms_alias  ## Alias to assign to the created KMS key when create_kms is true
  tags                  = var.tags
}
