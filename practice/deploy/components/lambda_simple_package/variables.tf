variable "source_path" {
  type        = string
  description = "Path to the Lambda source code directory"
}

variable "server_name" {
  type        = string
  description = "Name of the server/function (e.g., api_server, cron_server, worker)"
}

variable "output_dir" {
  type        = string
  description = "Directory where the zip file will be created (e.g., ../../out)."
}

variable "use_prebuilt_zip" {
  type        = bool
  default     = false
  description = "If true, use pre-built zip file from output_dir instead of creating with archive_file. Set to true when dependencies are installed via 'cb build'."
}

variable "prebuilt_zip_path" {
  type        = string
  default     = ""
  description = "Path to pre-built zip file. If empty, defaults to output_dir/server_name.zip"
}
