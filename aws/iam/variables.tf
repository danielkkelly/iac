variable "region" {}
variable "env" {}
variable "key_pair_name" {}
variable "iac_home" {}

variable users_groups {
  default = {
      dan = ["dev"]
    }
}

variable "networks" {
  type    = string
  default = "0.0.0.0/0"
}