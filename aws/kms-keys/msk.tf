resource "aws_kms_key" "msk_kms_key" {
  description = "platform-msk"
}

resource "aws_kms_alias" "msk_kms_alias" {
  name          = "alias/${var.env}-msk"
  target_key_id = aws_kms_key.msk_kms_key.id
}