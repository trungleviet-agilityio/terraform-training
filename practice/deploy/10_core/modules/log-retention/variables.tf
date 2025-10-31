variable "log_retention_in_days" {
  description = "Default log retention period in days. Valid values: 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365, 400, 545, 731, 1827, 3653"
  type        = number
  default     = 14

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_in_days)
    error_message = "log_retention_in_days must be one of: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365, 400, 545, 731, 1827, 3653"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
