# AWS
variable "region" {}
variable "key_pair_name" {}

# Environment
variable "env" {}

# EKS
variable "cluster_name" {
  default = "platform-eks"
}

#
# Network
#
variable "host_number" {
  default = "20"
}

# Variables that are passed to the eks module
variable cidr_block_subnet_pri_1 {}
variable cidr_block_subnet_pri_2 {}

# To silence TF warnings
variable cidr_block_vpc {}
variable cidr_block_subnet_pub_1 {}
variable cidr_block_subnet_pub_2 {}
variable cidr_block_subnet_rds_1 {}
variable cidr_block_subnet_rds_2 {}
variable cidr_block_subnet_vpn_1 {}