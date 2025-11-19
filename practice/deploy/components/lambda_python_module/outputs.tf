output "layer_zip_path" {
  description = "Path to the generated Lambda layer zip file"
  value       = local.signatures_data.layer_zip_path
}

output "app_zip_path" {
  description = "Path to the generated Lambda application zip file"
  value       = local.signatures_data.app_zip_path
}

output "requirements_file_path" {
  description = "Path to the generated requirements.txt file"
  value       = local.requirements_file
}

output "output_dir" {
  description = "Path to the output directory containing all generated artifacts"
  value       = local.output_dir
}

output "layer_zip_hash" {
  description = "Base64 SHA256 hash of the Lambda layer zip file for change detection"
  value       = base64encode(local.signatures_data.layer_sha256)
}

output "app_zip_hash" {
  description = "Base64 SHA256 hash of the Lambda application zip file for change detection"
  value       = base64encode(local.signatures_data.app_sha256)
}

output "lambda_layer_arn" {
  description = "ARN of the created Lambda layer"
  value       = aws_lambda_layer_version.dependencies_layer.arn
}

output "lambda_layer_version" {
  description = "Version of the created Lambda layer"
  value       = aws_lambda_layer_version.dependencies_layer.version
}

output "python_version" {
  description = "Python version used for the Lambda layer"
  value       = var.python_version
}
