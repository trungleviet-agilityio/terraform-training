# Import the main module
module "main" {
  source = "../../main"

  project_name = var.project_name
  environment  = var.environment
}
