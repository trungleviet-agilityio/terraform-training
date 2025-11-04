# Import the main module
module "main" {
  source = "../../main"

  project_name = var.project_name
  environment  = var.environment

  # GitHub OIDC Configuration (grouped)
  github_oidc_config = var.github_oidc_config

  # Backend Configuration (grouped)
  backend_config = var.backend_config
}
