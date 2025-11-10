/**
 * # Lambda Python Module
 *
 * This module packages a Python application using uv into:
 * 1. A Lambda layer zip file
 * 2. An application zip file
 *
 * The module uses change detection to only rebuild when necessary:
 * - Layer is rebuilt only when pyproject.toml changes
 * - App is rebuilt only when the src folder changes
 *
 * Expected package structure:
 * - package_root/
 *   - pyproject.toml
 *   - src/
 *     - package_name/
 *   - out/         # All artifacts will be placed here
 */

locals {
  # Get the absolute path to the deploy directory (parent of the components directory)
  deploy_dir            = abspath(dirname(dirname(path.module)))
  # Get the parent directory of the deploy directory
  cli_home              = dirname(local.deploy_dir)
  output_dir            = "${local.cli_home}/out/${var.package_name}"
  signatures_content_file = "${local.output_dir}/signatures.json"
  requirements_file     = "${local.output_dir}/requirements.txt"
  python_version        = var.python_version
  target_platform       = var.target_platform
}

# Data source to read the signatures.json file
data "local_file" "signatures" {
  filename = local.signatures_content_file
}

# Parse the JSON content
locals {
  signatures_data = jsondecode(data.local_file.signatures.content)
}

locals {
  s3_key = "${var.package_name}/${basename(local.signatures_data.layer_zip_path)}"
}

# Upload Layer zip object if required
resource "aws_s3_object" "layer_zip" {
  count = var.use_s3 ? 1 : 0

  bucket      = var.s3_bucket
  key         = local.s3_key
  source      = local.signatures_data.layer_zip_path
  source_hash = filemd5(local.signatures_data.layer_zip_path)
}

# Create AWS Lambda Layer
resource "aws_lambda_layer_version" "dependencies_layer" {
  filename            = var.use_s3 ? null : local.signatures_data.layer_zip_path
  s3_bucket           = var.use_s3 ? var.s3_bucket : null
  s3_key              = var.use_s3 ? aws_s3_object.layer_zip[0].key : null
  layer_name          = "${var.package_name}_dependencies"
  compatible_runtimes = ["python${var.python_version}"]
  description         = "Dependencies for ${var.package_name} Lambda function"
  source_code_hash    = filebase64sha256(local.signatures_data.layer_zip_path)

  depends_on = [
    aws_s3_object.layer_zip
  ]
}
