# Import the main module
module "main" {
  source = "../../main"

  # Pass providers through so module.main can use aws.us_east_1 for DNS certificates
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name              = var.project_name
  environment               = var.environment
  dns_config                = var.dns_config
  use_us_east_1_certificate = var.use_us_east_1_certificate
}
