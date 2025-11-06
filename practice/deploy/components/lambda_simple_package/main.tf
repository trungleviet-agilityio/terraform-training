# Determine the zip file path
locals {
  prebuilt_zip_path = var.prebuilt_zip_path != "" ? var.prebuilt_zip_path : "${var.output_dir}/${var.server_name}.zip"

  # Try to read pre-built zip file hash (will be null if file doesn't exist)
  prebuilt_zip_hash = var.use_prebuilt_zip ? try(filebase64sha256(local.prebuilt_zip_path), null) : null

  # Use pre-built zip if explicitly requested and file exists, otherwise use archive_file
  use_prebuilt = var.use_prebuilt_zip && local.prebuilt_zip_hash != null
}

# Package Lambda source code into a zip file (only if not using pre-built)
data "archive_file" "lambda_zip" {
  count       = local.use_prebuilt ? 0 : 1
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${var.output_dir}/${var.server_name}.zip"
}
