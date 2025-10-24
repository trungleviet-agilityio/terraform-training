# Terraform Configuration for Multi-Region AWS Providers
# This configuration demonstrates how to use multiple AWS provider instances
# to deploy resources across different AWS regions

terraform {
  # Minimum Terraform version requirement
  required_version = "~> 1.6"
  
  # Required providers and their versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default AWS Provider Configuration
# This is the primary AWS provider that will be used by default
# for all resources that don't specify a different provider
provider "aws" {
  region = "eu-west-1"  # Primary region for most resources
}

# Aliased AWS Provider Configuration
# This provider instance is aliased as "us-east" and targets the us-east-1 region
# Resources can explicitly use this provider by referencing aws.us-east
provider "aws" {
  region = "us-east-1"  # Secondary region for specific resources
  alias  = "us-east"   # Alias to reference this provider instance
}

# S3 Bucket in EU West 1 (Ireland)
# This bucket will be created in the eu-west-1 region using the default provider
resource "aws_s3_bucket" "eu_west_1" {
  bucket = "tf-demo-eu-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "Terraform Providers Demo - EU West 1"
    Environment = "Demo"
    Region      = "eu-west-1"
    Purpose     = "Multi-region provider demonstration"
}
}

# S3 Bucket in US East 1 (N. Virginia)
# This bucket will be created in the us-east-1 region using the aliased provider
# Note the provider = aws.us-east argument that specifies which provider to use
resource "aws_s3_bucket" "us_east_1" {
  bucket   = "tf-demo-us-${random_string.bucket_suffix.result}"
  provider = aws.us-east  # Explicitly use the aliased provider
  
  tags = {
    Name        = "Terraform Providers Demo - US East 1"
    Environment = "Demo"
    Region      = "us-east-1"
    Purpose     = "Multi-region provider demonstration"
  }
}

# Random string generator for unique bucket names
# This ensures bucket names are globally unique across AWS
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
