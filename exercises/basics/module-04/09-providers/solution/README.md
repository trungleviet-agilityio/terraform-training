# Multi-Region AWS Providers Solution

This solution demonstrates how to configure and use multiple AWS provider instances in Terraform to deploy resources across different AWS regions.

## Features

- **Multi-Region Deployment**: Resources deployed in both EU West 1 and US East 1 regions
- **Provider Aliasing**: Demonstrates how to use provider aliases for specific resources
- **Unique Naming**: Random string generation ensures globally unique S3 bucket names
- **Comprehensive Tagging**: Resources are properly tagged for identification and management

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   EU West 1     │    │   US East 1     │
│   (eu-west-1)   │    │   (us-east-1)   │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ S3 Bucket   │ │    │ │ S3 Bucket   │ │
│ │ (Default    │ │    │ │ (Aliased    │ │
│ │ Provider)   │ │    │ │ Provider)   │ │
│ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘
```

## Files Overview

- `providers.tf` - Complete Terraform configuration with multi-region setup

## Configuration Details

### Provider Configuration

1. **Default Provider**: Targets `eu-west-1` region
2. **Aliased Provider**: Targets `us-east-1` region with alias `us-east`

### Resources Created

- **S3 Bucket (EU West 1)**: Uses default provider
- **S3 Bucket (US East 1)**: Uses aliased provider
- **Random String**: Generates unique suffix for bucket names

## Usage

### Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform version 1.6 or later
3. Access to both EU West 1 and US East 1 regions

### Deployment

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

### Verification

After deployment, verify the resources:

1. **Check EU West 1 bucket**:
   ```bash
   aws s3 ls --region eu-west-1
   ```

2. **Check US East 1 bucket**:
   ```bash
   aws s3 ls --region us-east-1
   ```

## Key Concepts Demonstrated

### Provider Aliasing

```hcl
# Default provider (no alias)
provider "aws" {
  region = "eu-west-1"
}

# Aliased provider
provider "aws" {
  region = "us-east-1"
  alias  = "us-east"
}
```

### Resource Provider Assignment

```hcl
# Uses default provider
resource "aws_s3_bucket" "eu_west_1" {
  bucket = "tf-demo-eu-${random_string.bucket_suffix.result}"
}

# Uses aliased provider
resource "aws_s3_bucket" "us_east_1" {
  bucket   = "tf-demo-us-${random_string.bucket_suffix.result}"
  provider = aws.us-east
}
```

## Best Practices Implemented

1. **Unique Naming**: Random string generation prevents naming conflicts
2. **Comprehensive Tagging**: All resources are properly tagged
3. **Clear Documentation**: Extensive comments explain each configuration
4. **Provider Separation**: Clear distinction between default and aliased providers
5. **Bucket Name Length**: Shortened names to stay under S3's 63-character limit

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Note**: This will destroy both S3 buckets in both regions. Make sure to backup any important data before running destroy.

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure AWS credentials have access to both regions
2. **Bucket Name Conflicts**: The random string generator should prevent this
3. **Provider Not Found**: Verify the alias is correctly referenced

### Debug Commands

```bash
# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list
```
