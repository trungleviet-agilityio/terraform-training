variable "package_root" {
  description = "Path to the Python package root directory containing pyproject.toml and src/"
  type        = string
}

variable "package_name" {
  description = "Name of the Python package, used for naming the Lambda layer"
  type        = string
}

variable "python_version" {
  description = "Python version to target for the Lambda layer"
  type        = string
  default     = "3.13"
}

variable "target_platform" {
  description = "Target platform for the Lambda layer packages"
  type        = string
  default     = "manylinux2014_x86_64"
}

variable "use_s3" {
  description = "If true, upload the zip to S3 and use s3_bucket/s3_key instead of filename"
  type        = bool
  default     = false
}

variable "s3_bucket" {
  description = "S3 bucket for storing Lambda layers"
  type        = string
  default     = null
}
