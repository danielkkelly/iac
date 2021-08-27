locals {
  log_path = "/${var.namespace}/${var.env}/${var.name}"
}

resource "aws_cloudwatch_log_group" "cloudwatch_lg" {
  name              = var.use_default_name ? local.log_path : var.name
  retention_in_days = var.retention_in_days
}