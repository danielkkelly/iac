variable "bucket_name" {}

variable "replication_region" {
  description = "The destination region for bucket replication"
  default     = "us-west-1"
}

variable "object_lock_enabled" {
  type    = bool
  default = false
}