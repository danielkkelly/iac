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

#
# Network
#

variable "private_ip" {
  default	= "10.0.2.20"
}
