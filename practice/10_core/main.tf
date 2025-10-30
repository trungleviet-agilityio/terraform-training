data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "this" {
  count                   = var.create_kms ? 1 : 0
  description             = "tt-practice CMK for optional encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "this" {
  count         = var.create_kms ? 1 : 0
  name          = var.kms_alias
  target_key_id = aws_kms_key.this[0].key_id
}
