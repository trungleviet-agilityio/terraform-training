output "practice_util" {
  value = {
    lambda_layer_arn = module.practice_util.lambda_layer_arn
    app_zip_path     = module.practice_util.app_zip_path
    layer_zip_path   = module.practice_util.layer_zip_path
    app_zip_hash     = module.practice_util.app_zip_hash
    layer_zip_hash   = module.practice_util.layer_zip_hash
  }
  description = "Package information for practice_util runtime module"
}

output "api_server" {
  value = {
    zip_path         = module.api_server_package.app_zip_path
    zip_hash         = module.api_server_package.app_zip_hash
    lambda_layer_arn = module.api_server_package.lambda_layer_arn
  }
  description = "Package information for API Server Lambda"
}

output "cron_server" {
  value = {
    zip_path         = module.cron_server_package.app_zip_path
    zip_hash         = module.cron_server_package.app_zip_hash
    lambda_layer_arn = module.cron_server_package.lambda_layer_arn
  }
  description = "Package information for Cron Server Lambda"
}

output "worker" {
  value = {
    zip_path         = module.worker_package.app_zip_path
    zip_hash         = module.worker_package.app_zip_hash
    lambda_layer_arn = module.worker_package.lambda_layer_arn
  }
  description = "Package information for Worker Lambda"
}
