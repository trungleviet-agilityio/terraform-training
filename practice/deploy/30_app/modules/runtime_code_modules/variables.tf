variable "source_base_path" {
  type        = string
  description = "Base path to Lambda source code directory (e.g., ../../src/lambda). Not used directly, kept for compatibility."
  default     = ""
}

variable "output_dir" {
  type        = string
  description = "Directory where zip files will be created (e.g., ../../out). Not used directly, kept for compatibility."
  default     = ""
}
