# Environment
variable "region" {}
variable "key_pair_name" {}
variable "env" {}

# Network and subnets
variable "cidr_block_vpc" {}
variable "cidr_block_subnet_pub_1" {}
variable "cidr_block_subnet_pub_2" {}
variable "cidr_block_subnet_pri_1" {}
variable "cidr_block_subnet_pri_2" {}

# RDS
variable "cidr_block_subnet_rds_1" {}
variable "cidr_block_subnet_rds_2" {}

# VPN
variable "cidr_block_subnet_vpn_1" {}

# EKS
variable "eks_cluster_name" {
  default = "platform-eks"
}

# Cloudwatch
variable "cloudwatch_retention_in_days" {
  default = 365
}