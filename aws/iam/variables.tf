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

variable users_groups {
  default = {
      user1 = ["dev"]
      user2 = ["dev-admin"]
    }
}