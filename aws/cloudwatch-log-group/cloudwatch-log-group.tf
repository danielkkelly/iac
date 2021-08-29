locals {
  default_name = "/${var.namespace}/${var.env}/${var.name}"

  log_name = var.use_default_name ? local.default_name : var.name
}

/*
 * One CMK for all of the CloudWatch logs.  Need to look it up.
 */
data "aws_kms_key" "cloudwatch_kms_key" {
  key_id = "alias/${var.env}-cloudwatch"
}

/*
 * Create the log group
 */
resource "aws_cloudwatch_log_group" "cloudwatch_lg" {
  name              = local.log_name
  kms_key_id        = data.aws_kms_key.cloudwatch_kms_key.arn
  retention_in_days = var.retention_in_days
}