# CloudWatch Log Retention Module

This module manages CloudWatch log group retention settings and provides a default retention policy.

## Resources

- CloudWatch log group retention policy (via data source or resource)

## Usage

```hcl
module "log_retention" {
  source = "../modules/log-retention"

  log_retention_in_days = var.log_retention_in_days
  tags                  = var.tags
}
```

## Variables

- `log_retention_in_days`: Default retention period in days (14, 30, 60, 90, 120, 180, 365, 400, 545, 731, 1827, 3653, or 0 for never expire)
- `tags`: Tags to apply to resources

## Outputs

- `retention_days`: The configured retention period in days

## Notes

This module doesn't create log groups directly. Instead, it provides the retention configuration that can be referenced by other modules. Log groups are typically created by the services that use them (Lambda, API Gateway, etc.).

To apply retention to existing log groups, use `aws logs put-retention-policy` CLI command or create a resource per log group.

