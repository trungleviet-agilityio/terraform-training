# DynamoDB table for Terraform state locking
# This table is used by the S3 backend to prevent concurrent state modifications
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Production"
    Purpose     = "Terraform State Locking"
  }
}
