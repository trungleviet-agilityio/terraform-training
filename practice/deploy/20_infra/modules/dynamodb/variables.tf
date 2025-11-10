variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "tables" {
  description = "Map of DynamoDB table configurations"
  type = map(object({
    # Required: Partition key (hash key)
    partition_key = string

    # Optional: Sort key (range key) - used for time-series tables
    sort_key = optional(string)

    # Optional: Attribute types map (defaults to "S" for string)
    attribute_types = optional(map(string), {})

    # Optional: Table type (key-value or time-series)
    type = optional(string, "key-value")

    # Optional: Billing mode (PAY_PER_REQUEST or PROVISIONED)
    billing_mode = optional(string, "PAY_PER_REQUEST")

    # Optional: Enable TTL (for time-series tables)
    enable_ttl    = optional(bool, false)
    ttl_attribute = optional(string, "ttl")

    # Optional: Enable point-in-time recovery
    enable_point_in_time_recovery = optional(bool, false)

    # Optional: Enable DynamoDB Streams
    enable_stream    = optional(bool, false)
    stream_view_type = optional(string, "NEW_AND_OLD_IMAGES")

    # Optional: KMS key ID for encryption (uses default AWS managed key if null)
    kms_key_id = optional(string)

    # Optional: Purpose description for tags
    purpose = optional(string, "Application Data Storage")
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
