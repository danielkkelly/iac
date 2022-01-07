#
# AWS Region
#
variable "region" {
}

variable "brokers" {
  default = ["kafka-broker1", "kafka-broker2"]
}

#
# Specifies the environment
#
variable "env" {
}

# Variables that help allow private network access to the RDS server
variable "cidr_block_subnet_pri_1" {}
variable "cidr_block_subnet_pri_2" {}
variable "cidr_block_subnet_vpn_1" {}

# To silence TF warnings
variable "key_pair_name" {}
variable "cidr_block_vpc" {}
variable "cidr_block_subnet_pub_1" {}
variable "cidr_block_subnet_pub_2" {}
variable "cidr_block_subnet_rds_1" {}
variable "cidr_block_subnet_rds_2" {}