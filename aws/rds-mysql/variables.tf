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

# Cluster

variable "rds_instance_count" {
  default = 2
}

variable "rds_instance_class" {
  default = "db.t2.medium"
}

# Database

variable "master_username" {
  default = "manager"
}
variable "master_password" {
  default = "top-s3cr3t!"
}

variable "preferred_backup_window" {
  default = "04:00-06:00"
}

variable "backup_retention_period" {
  default = 14
}

# Variables that help allow private network access to the RDS server
variable "cidr_block_subnet_pri_1" {
}

variable "cidr_block_subnet_pri_2" {
}

variable "cidr_block_subnet_vpn_1" {
}

# To silence TF warnings
variable "key_pair_name" {
}
variable "cidr_block_vpc" {
}
variable "cidr_block_subnet_pub_1" {
}
variable "cidr_block_subnet_pub_2" {
}
variable "cidr_block_subnet_rds_1" {
}
variable "cidr_block_subnet_rds_2" {
}