locals {
  log_path = "/aws/rds/cluster/${var.rds_cluster_identifier}"
}

module "cluster_audit_lg" {
  source           = "../cloudwatch-log-group"
  use_default_name = false
  env              = var.env
  region           = var.region
  name             = "${local.log_path}/audit"
}

module "cluster_error_lg" {
  source           = "../cloudwatch-log-group"
  use_default_name = false
  env              = var.env
  region           = var.region
  name             = "${local.log_path}/error"
}

module "cluster_general_lg" {
  source           = "../cloudwatch-log-group"
  use_default_name = false
  env              = var.env
  region           = var.region
  name             = "${local.log_path}/general"
}

module "cluster_slowquery_lg" {
  source           = "../cloudwatch-log-group"
  use_default_name = false
  env              = var.env
  region           = var.region
  name             = "${local.log_path}/slowquery"
}