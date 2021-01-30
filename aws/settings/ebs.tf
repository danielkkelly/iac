# New instances should have volumes encrypted by default
resource "aws_ebs_encryption_by_default" "ebs_encryptiopn_by_default" {
  enabled = true
}