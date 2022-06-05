# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}

# Security Group
variable "ingress" {
  type    = list(any)
  default = ["0.0.0.0/0"]
}

# Host
variable "instance_type" {
  default = "t2.xlarge"
}

variable "username" {
  default = "manager"
}
variable "password" {
  default = "top-s3cr3t!$"
}

variable "maintenance_window_start_time" {
  description = "Describe the Maintenance window block"
  type        = map(any)
  default = {
    day_of_week = "MONDAY"
    time_of_day = "12:05"
    time_zone   = "GMT"
  }
}

# Variables that help allow private network access to the RDS server
variable "cidr_block_subnet_vpn_1" {}

# To silence TF warnings
variable "cidr_block_vpc" {}
variable "cidr_block_subnet_pub_1" {}
variable "cidr_block_subnet_pub_2" {}
variable "cidr_block_subnet_pri_1" {}
variable "cidr_block_subnet_pri_2" {}
variable "cidr_block_subnet_rds_1" {}
variable "cidr_block_subnet_rds_2" {}
