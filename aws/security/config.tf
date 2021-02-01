resource "aws_iam_role" "config_role" {
  name = "platform-config-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "config_role_policy_attachment" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "random_id" "random_s3_index" {
  byte_length = 4
}

resource "aws_s3_bucket" "config_s3_bucket" {
  bucket        = "platform-config-${var.env}-${random_id.random_s3_index.hex}"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_s3_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow bucket ACL check",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"
        ]
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.config_s3_bucket.arn}",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    },
    {
      "Sid": "Allow bucket write",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"
        ]
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.config_s3_bucket.arn}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        },
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    },
    {
      "Sid": "Require SSL",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "${aws_s3_bucket.config_s3_bucket.arn}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "platform-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

module "default_sns" {
  source = "../sns"

  monthly_spend_limit    = 1
  topic_name             = "platform-sms-topic"
  topic_display_name     = "platform-sms-topic"
  usage_report_s3_bucket = "platform-sms-usage-bucket-${var.env}"

  subscriptions = [
    var.sms_number
  ]
}

# TODO: SNS (sns_topic_arn)
resource "aws_config_delivery_channel" "config_delivery_channel" {
  name           = "platform-config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_s3_bucket.bucket

  depends_on = [aws_config_configuration_recorder.config_recorder]
}

resource "aws_config_configuration_recorder_status" "config_recorder_status" {
  name       = aws_config_configuration_recorder.config_recorder.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.config_delivery_channel]
}