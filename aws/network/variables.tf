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
# Network and subnets
#
variable "cidr_block_vpc" {
}

variable "cidr_block_subnet_pub_1" {
}

variable "cidr_block_subnet_pub_2" {
}

variable "cidr_block_subnet_pri_1" {
}

variable "cidr_block_subnet_pri_2" {
}

#
# RDS
#
variable cidr_block_subnet_rds_1 {
}

variable cidr_block_subnet_rds_2 {
}

