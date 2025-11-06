output "zip_path" {
  value       = local.use_prebuilt ? local.prebuilt_zip_path : data.archive_file.lambda_zip[0].output_path
  description = "Path to the zip file (either pre-built or created by archive_file)"
}

output "zip_hash" {
  value       = local.use_prebuilt ? local.prebuilt_zip_hash : data.archive_file.lambda_zip[0].output_base64sha256
  description = "Base64-encoded SHA256 hash of the zip file"
}
