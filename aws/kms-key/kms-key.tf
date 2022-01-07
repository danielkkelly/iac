resource "aws_kms_key" "kms_key" {
  description         = "platform-${var.name}"
  enable_key_rotation = true
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.env}-${var.name}"
  target_key_id = aws_kms_key.kms_key.id
}