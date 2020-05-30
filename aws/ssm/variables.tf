#
# AWS Region
#
variable "region" {
}

#
# Specifies the environment
#
variable "env" {
}

variable "key_pair_name" {
}

variable "mw_cron" {
  default = "cron(*/30 * ? * * *)"
}