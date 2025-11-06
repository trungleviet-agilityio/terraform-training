# Package API Server Lambda code
module "api_server_package" {
  source = "../../../components/lambda_simple_package"

  source_path = "${var.source_base_path}/api_server"
  server_name = "api_server"
  output_dir  = var.output_dir
}

# Package Cron Server Lambda code
module "cron_server_package" {
  source = "../../../components/lambda_simple_package"

  source_path = "${var.source_base_path}/cron_server"
  server_name = "cron_server"
  output_dir  = var.output_dir
}

# Package Worker Lambda code
module "worker_package" {
  source = "../../../components/lambda_simple_package"

  source_path = "${var.source_base_path}/worker"
  server_name = "worker"
  output_dir  = var.output_dir
}
