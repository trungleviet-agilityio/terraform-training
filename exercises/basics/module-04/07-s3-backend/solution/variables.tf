# Variables for S3 Backend Configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "backend_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string
  default     = "my-terraform-remote-backend-bucket"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-project"
}

variable "enable_state_locking" {
  description = "Enable DynamoDB state locking"
  type        = bool
  default     = true
}
