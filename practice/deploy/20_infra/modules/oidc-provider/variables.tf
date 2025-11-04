variable "name" {
  type        = string
  description = "Name for the OIDC provider resource."
  default     = "oidc-provider-github-actions"

  validation {
    condition     = length(var.name) > 0
    error_message = "Name must be a non-empty string."
  }
}

variable "thumbprint_list" {
  type        = list(string)
  description = "List of server certificate thumbprints for the OIDC provider. GitHub Actions uses specific thumbprints."
  # GitHub Actions OIDC thumbprints (as of 2024)
  # These are the root certificates used by GitHub Actions
  default = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  validation {
    condition     = length(var.thumbprint_list) > 0
    error_message = "At least one thumbprint must be provided."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the OIDC provider."
  default     = {}
}
