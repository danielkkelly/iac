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
  default = "10.0.1.10"
}

variable "cidr_blocks_ingress" {
  default = ["0.0.0.0/0"]
}