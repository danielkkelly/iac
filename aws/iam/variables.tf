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
  desciption = "Specifies one or more allowable source IP ranges for AWS API use, defaults to all"
  type    = string
  default = "\"0.0.0.0/0\""
}