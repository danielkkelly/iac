variable "name" {
  description = "Adds a category specific name to the S3 bucket default name format (e.g. platform-<name>-<env>-random)"
  type        = string
}

variable "env" {
  description = "Adds environment context to the S3 bucket default name format (e.g. platform-<name>-<env>-random)"
  type        = string
}

variable "versioning_enabled" {
  description = "True if versioning is enabled, false if not.  Default is false"
  type        = bool
  default     = false
}