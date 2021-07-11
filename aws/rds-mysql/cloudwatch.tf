locals {
    log_path = "/aws/rds/instance/${var.rds_cluster_identifier}"
}

resource "aws_cloudwatch_log_group" "audit" {
  name = "${local.log_path}/audit"
  retention_in_days = var.cloudwatch_retention_in_days
}

resource "aws_cloudwatch_log_group" "error" {
  name = "${local.log_path}/error"
  retention_in_days = var.cloudwatch_retention_in_days
}

resource "aws_cloudwatch_log_group" "general" {
  name = "${local.log_path}/general"
  retention_in_days = var.cloudwatch_retention_in_days
}

resource "aws_cloudwatch_log_group" "slowquery" {
  name = "${local.log_path}/slowquery"
  retention_in_days = var.cloudwatch_retention_in_days
}