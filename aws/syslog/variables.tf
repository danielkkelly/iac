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

variable "host_number" {
  default = "20"
}

# Variables that help allow private network access to the RDS server
variable cidr_block_subnet_pri_1 {}
variable cidr_block_subnet_pri_2 {}

# To silence TF warnings
variable cidr_block_vpc {}
variable cidr_block_subnet_pub_1 {}
variable cidr_block_subnet_pub_2 {}
variable cidr_block_subnet_rds_1 {}
variable cidr_block_subnet_rds_2 {}
variable cidr_block_subnet_vpn_1 {}
