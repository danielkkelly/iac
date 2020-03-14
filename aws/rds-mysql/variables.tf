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

variable rds_instance_count {
  default = 1
}

variable rds_instance_class {
  default = "db.t2.small"
}

#
# Network
#

variable cidr_block_subnet_rds_1 {
  default = "10.0.100.0/24"
}

variable cidr_block_subnet_rds_2 {
  default = "10.0.102.0/24"
}
