
# Environment
variable "env" {}

# SNS SMS
variable "default_sender_id" {
  description = "A custom ID, such as your business brand, displayed as the sender on the receiving device. Support for sender IDs varies by country."
  type        = string
  default     = ""
}

variable "default_sms_type" {
  description = "Promotional messages are noncritical, such as marketing messages. Transactional messages are delivered with higher reliability to support customer transactions, such as one-time passcodes."
  type        = string
  default     = "Transactional"
}

variable "delivery_status_success_sampling_rate" {
  description = "Default percentage of success to sample."
  type        = number
  default     = 0
}

variable "monthly_spend_limit" {
  description = "The maximum amount to spend on SMS messages each month. If you send a message that exceeds your limit, Amazon SNS stops sending messages within minutes."
  type        = number
}

variable "usage_report_s3_bucket" {
  description = "The Amazon S3 bucket to receive daily SMS usage reports. The bucket policy must grant write access to Amazon SNS."
  type        = string
}