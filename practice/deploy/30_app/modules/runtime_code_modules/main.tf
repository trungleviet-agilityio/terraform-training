/*
This module packages the Lambda source code into zip files for deployment.
*/

# Package API Server Lambda code
module "api_server_package" {
  source = "../../../components/lambda_simple_package"

  source_path      = "${var.source_base_path}/api_server"
  server_name      = "api_server"
  output_dir       = var.output_dir
  use_prebuilt_zip = true  # Use pre-built zip from cb build (includes dependencies)
}

# Package Cron Server Lambda code
module "cron_server_package" {
  source = "../../../components/lambda_simple_package"

  source_path      = "${var.source_base_path}/cron_server"
  server_name      = "cron_server"
  output_dir       = var.output_dir
  use_prebuilt_zip = true  # Use pre-built zip from cb build (includes dependencies)
}

# Package Worker Lambda code
module "worker_package" {
  source = "../../../components/lambda_simple_package"

  source_path      = "${var.source_base_path}/worker"
  server_name      = "worker"
  output_dir       = var.output_dir
  use_prebuilt_zip = true  # Use pre-built zip from cb build (includes dependencies)
}
