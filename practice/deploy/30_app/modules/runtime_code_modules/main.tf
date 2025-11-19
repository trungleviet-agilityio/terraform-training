/*
This module packages the Lambda source code and runtime modules into zip files for deployment.
*/

# Package practice_util runtime module (creates Lambda layer)
module "practice_util" {
  source = "../../../components/lambda_python_module"

  package_root   = "${path.root}/../../../../src/runtime/practice_util"
  package_name   = "practice_util"
  python_version = "3.13"
  use_s3         = false
}

# Package API Server Lambda code (uses practice_util layer)
module "api_server_package" {
  source = "../../../components/lambda_python_module"

  package_root   = "${path.root}/../../../../src/lambda/api_server"
  package_name   = "api_server"
  python_version = "3.13"
  use_s3         = false
}

# Package Cron Server Lambda code (uses practice_util layer)
module "cron_server_package" {
  source = "../../../components/lambda_python_module"

  package_root   = "${path.root}/../../../../src/lambda/cron_server"
  package_name   = "cron_server"
  python_version = "3.13"
  use_s3         = false
}

# Package Worker Lambda code (uses practice_util layer)
module "worker_package" {
  source = "../../../components/lambda_python_module"

  package_root   = "${path.root}/../../../../src/lambda/worker"
  package_name   = "worker"
  python_version = "3.13"
  use_s3         = false
}
