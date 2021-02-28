# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}
variable "iac_home" {}

# Users and groups
variable "users_groups" {
  default = {
    dan = ["dev"]
  }
}

# Networks
variable "networks" {
  description = "Source IP ranges for AWS API use"
  type        = string
  default     = "\"0.0.0.0/0\""
}