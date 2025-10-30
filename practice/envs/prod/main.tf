module "core" {
  source       = "../../10_core"
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags

  create_kms = false
}

module "infra" {
  source       = "../../20_infra"
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

module "app" {
  source       = "../../30_app"
  project_name = var.project_name
  environment  = var.environment
  deploy_mode  = var.deploy_mode
  tags         = var.tags
}
