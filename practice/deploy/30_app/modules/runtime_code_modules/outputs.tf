output "api_server" {
  value = {
    zip_path = module.api_server_package.zip_path
    zip_hash = module.api_server_package.zip_hash
  }
  description = "Package information for API Server Lambda"
}

output "cron_server" {
  value = {
    zip_path = module.cron_server_package.zip_path
    zip_hash = module.cron_server_package.zip_hash
  }
  description = "Package information for Cron Server Lambda"
}

output "worker" {
  value = {
    zip_path = module.worker_package.zip_path
    zip_hash = module.worker_package.zip_hash
  }
  description = "Package information for Worker Lambda"
}
