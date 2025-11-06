# Data source for account ID
data "aws_caller_identity" "current" {}

# DynamoDB Tables
resource "aws_dynamodb_table" "tables" {
  for_each = var.tables

  name         = "${var.project_name}-${var.environment}-${each.key}"
  billing_mode = lookup(each.value, "billing_mode", "PAY_PER_REQUEST")

  # Hash key (partition key) - required for all tables
  hash_key = each.value.partition_key

  # Range key (sort key) - optional, used for time-series tables
  range_key = lookup(each.value, "sort_key", null)

  # Attribute definitions
  dynamic "attribute" {
    for_each = concat(
      [each.value.partition_key],
      lookup(each.value, "sort_key", null) != null ? [each.value.sort_key] : []
    )
    content {
      name = attribute.value
      type = lookup(each.value.attribute_types, attribute.value, "S")
    }
  }

  # TTL configuration (for time-series tables)
  dynamic "ttl" {
    for_each = lookup(each.value, "enable_ttl", false) ? [1] : []
    content {
      attribute_name = lookup(each.value, "ttl_attribute", "ttl")
      enabled        = true
    }
  }

  # Point-in-time recovery (optional)
  point_in_time_recovery {
    enabled = lookup(each.value, "enable_point_in_time_recovery", false)
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
    # Note: Custom KMS keys are not directly supported in server_side_encryption block
    # Use AWS managed key (default) or configure encryption at table level if needed
  }

  # Stream configuration (optional)
  stream_enabled   = lookup(each.value, "enable_stream", false)
  stream_view_type = lookup(each.value, "enable_stream", false) ? lookup(each.value, "stream_view_type", "NEW_AND_OLD_IMAGES") : null

  # Tags
  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-${each.key}"
      Purpose = lookup(each.value, "purpose", "Application Data Storage")
      Type    = lookup(each.value, "type", "key-value")
    }
  )
}
