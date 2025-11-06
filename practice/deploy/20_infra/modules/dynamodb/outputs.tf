output "table_names" {
  description = "Map of table names (key -> table name)"
  value = {
    for k, v in aws_dynamodb_table.tables : k => v.name
  }
}

output "table_arns" {
  description = "Map of table ARNs (key -> table ARN)"
  value = {
    for k, v in aws_dynamodb_table.tables : k => v.arn
  }
}

output "table_stream_arns" {
  description = "Map of table stream ARNs (key -> stream ARN, null if stream not enabled)"
  value = {
    for k, v in aws_dynamodb_table.tables : k => v.stream_arn
  }
}

output "tables" {
  description = "Map of all table information (key -> object with name, arn, stream_arn)"
  value = {
    for k, v in aws_dynamodb_table.tables : k => {
      name       = v.name
      arn        = v.arn
      stream_arn = v.stream_arn
    }
  }
}
