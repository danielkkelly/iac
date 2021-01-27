resource "aws_securityhub_account" "platform_sh_account" {}

resource "aws_securityhub_standards_subscription" "platform_sh_standards_subscription" {
  depends_on    = [aws_securityhub_account.platform_sh_account]
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
}