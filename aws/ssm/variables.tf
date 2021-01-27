# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}

# Maintenance window cron expression
variable "mw_cron" {
  default = "cron(*/30 * ? * * *)"
}