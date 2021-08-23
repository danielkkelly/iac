# Environment
variable "region" {}
variable "env" {}

# Cluster
variable "rds_cluster_identifier" {
  description = "Name of the cluster"
  default     = "platform-rds-cluster"
}

variable "rds_instance_count" {
  description = "Number of cluster instances, use two or more for most professional environments"
  default     = 1
}

variable "rds_instance_class" {
  default = "db.t2.medium"
}

variable "rds_deletion_protection" {
  default = "false"
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

variable "backtrack_window_seconds" {
  default = 43200 # 12 hours
}

variable "enhanced_monitoring_interval" {
  description = "Monitoring inteval for ehnanced monitoring"
  default     = 60
}

# Cluster and DB parameters
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Reference.html#AuroraMySQL.Reference.ParameterGroups
variable "instance_parameters" {
  description = "List of database parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = [
    {
      name         = "max_allowed_packet"
      value        = "64MB"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_bin_trust_function_creators"
      value        = "1"
      apply_method = "pending-reboot"
    },
    {
      name         = "general_log"
      value        = "1"
      apply_method = "pending-reboot"
    },
    {
      name         = "slow_query_log"
      value        = "1"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_output"
      value        = "FILE"
      apply_method = "pending-reboot"
    }
  ]
}

variable "max_allowed_packet" {
  default = "64MB"
}

# Cloudwatch
variable "cloudwatch_retention_in_days" {
  default = 365
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