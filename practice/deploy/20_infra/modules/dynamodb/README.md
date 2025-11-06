# DynamoDB Module

This module creates DynamoDB tables for application data storage in the 20_infra layer.

## Purpose

Creates one or more DynamoDB tables with support for:
- **Key-value tables**: Simple primary key (partition key only)
- **Time-series tables**: Partition key + sort key with optional TTL

## Resources

- DynamoDB tables with configurable attributes
- Optional TTL configuration for time-series data
- Optional DynamoDB Streams
- Server-side encryption (default AWS managed key)
- Optional point-in-time recovery

## Usage

### Key-Value Table Example

```hcl
module "dynamodb" {
  source = "../modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  tables = {
    "user-data" = {
      partition_key = "user_id"
      type          = "key-value"
      attribute_types = {
        user_id = "S"
      }
      enable_point_in_time_recovery = true
    }
  }

  tags = local.common_tags
}
```

### Time-Series Table Example

```hcl
module "dynamodb" {
  source = "../modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  tables = {
    "events" = {
      partition_key = "event_type"
      sort_key      = "timestamp"
      type          = "time-series"
      attribute_types = {
        event_type = "S"
        timestamp  = "N"
      }
      enable_ttl = true
      ttl_attribute = "ttl"
      enable_stream = true
    }
  }

  tags = local.common_tags
}
```

## Variables

- `project_name` (required): Project name for resource naming
- `environment` (required): Environment name (e.g., dev, stage, prod)
- `tables` (optional): Map of table configurations. Default: `{}`
- `tags` (optional): Tags to apply to all resources. Default: `{}`

### Table Configuration Options

Each table in the `tables` map supports:

- `partition_key` (required): Name of the partition key attribute
- `sort_key` (optional): Name of the sort key attribute (for time-series tables)
- `attribute_types` (optional): Map of attribute names to types ("S" for string, "N" for number, "B" for binary). Defaults to "S" for all attributes
- `type` (optional): Table type - "key-value" or "time-series". Default: "key-value"
- `billing_mode` (optional): "PAY_PER_REQUEST" or "PROVISIONED". Default: "PAY_PER_REQUEST"
- `enable_ttl` (optional): Enable TTL for automatic item expiration. Default: `false`
- `ttl_attribute` (optional): Name of the TTL attribute. Default: "ttl"
- `enable_point_in_time_recovery` (optional): Enable point-in-time recovery. Default: `false`
- `enable_stream` (optional): Enable DynamoDB Streams. Default: `false`
- `stream_view_type` (optional): Stream view type when streams are enabled. Valid values: "KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES". Default: "NEW_AND_OLD_IMAGES". Only used when `enable_stream` is `true`
- `kms_key_id` (optional): KMS key ID for encryption (uses default AWS managed key if null). Note: Custom KMS keys are not directly supported in the server_side_encryption block; AWS managed key is used by default
- `purpose` (optional): Purpose description for tags. Default: "Application Data Storage"

## Outputs

- `table_names`: Map of table names (key -> table name)
- `table_arns`: Map of table ARNs (key -> table ARN)
- `table_stream_arns`: Map of table stream ARNs (key -> stream ARN, null if stream not enabled)
- `tables`: Map of all table information (key -> object with name, arn, stream_arn)

## Stream Configuration

DynamoDB Streams are configured using the `stream_enabled` and `stream_view_type` attributes (not a nested block):

- When `enable_stream = true`: Streams are enabled with the specified `stream_view_type`
- When `enable_stream = false`: Streams are disabled and `stream_view_type` is set to `null`

**Stream View Types**:
- `KEYS_ONLY`: Only the key attributes of the modified item
- `NEW_IMAGE`: The entire item as it appears after it was modified
- `OLD_IMAGE`: The entire item as it appears before it was modified
- `NEW_AND_OLD_IMAGES`: Both the new and old images of the item

## IAM Permissions

Lambda functions that need to access DynamoDB tables require IAM permissions. Add DynamoDB policies to Lambda execution roles:

```hcl
# Example: Grant read/write access to all tables
data "aws_iam_policy_document" "dynamodb_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      module.dynamodb.table_arns["user-data"],
      module.dynamodb.table_arns["events"]
    ]
  }
}
```

## Best Practices

1. **Key-Value Tables**: Use for simple lookups, user data, configuration
2. **Time-Series Tables**: Use for events, logs, metrics with timestamp-based queries
3. **TTL**: Enable for time-series data that should expire automatically
4. **Streams**: Enable if you need to process changes in real-time (e.g., Lambda triggers)
5. **Point-in-Time Recovery**: Enable for production tables with critical data
6. **Billing Mode**: Use PAY_PER_REQUEST for variable workloads, PROVISIONED for predictable workloads

## Example: Multiple Tables

```hcl
tables = {
  "user-data" = {
    partition_key = "user_id"
    type          = "key-value"
    enable_point_in_time_recovery = true
  }
  
  "events" = {
    partition_key = "event_type"
    sort_key      = "timestamp"
    type          = "time-series"
    attribute_types = {
      event_type = "S"
      timestamp  = "N"
    }
    enable_ttl = true
    ttl_attribute = "ttl"
  }
  
  "sessions" = {
    partition_key = "session_id"
    type          = "key-value"
    enable_ttl = true
    ttl_attribute = "expires_at"
  }
}
```
