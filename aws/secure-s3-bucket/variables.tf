variable "name" {
  description = "Adds a category specific name to the S3 bucket default name format (e.g. platform-<name>-<env>-random)"
  type        = string
}

variable "env" {
  description = "Adds environment context to the S3 bucket default name format (e.g. platform-<name>-<env>-random)"
  type        = string
}

variable "versioning_enabled" {
  description = "True if versioning is enabled, false if not.  Default is true"
  type        = bool
  default     = true
}

variable "logging_enabled" {
  description = "True if a logging bucket should be created, false if not.  Default is true"
  type        = bool
  default     = true
}

/*
 * Note: Object Lock and Replication require a token from AWS support.  Then a call 
 * is made via the CLI to enable replication.  This functionality is currently not
 * supported by terraform.  See https://github.com/hashicorp/terraform-provider-aws/issues/14061.
 */
variable "replication_region" {
  description = "The destination region for bucket replication"
  default     = "us-west-1"
}

variable "replication_enabled" {
  type    = bool
  default = true
}

variable "object_lock_enabled" {
  type    = bool
  default = false
}