# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}

variable "replication_region" {
    description = "Region into which we replicate backups, set globally via environment variable"
}

variable "retention_in_days" {
    default = 14
}

variable "schedule_cron" {
    default = "cron(0 5 ? * * *)" /* UTC Time */
}