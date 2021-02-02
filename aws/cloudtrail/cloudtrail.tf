provider "aws" {
  region  = var.region
  profile = var.env
}

module "default_s3_bucket" {
  source = "../s3-bucket"
  name   = "cloudtrail"
  env    = var.env
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = module.default_s3_bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${module.default_s3_bucket.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${module.default_s3_bucket.arn}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "Require SSL",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "*",
            "Resource": "${module.default_s3_bucket.arn}/*",
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

resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name = "cloudtrail"
}

resource "aws_cloudtrail" "cloudtrail" {
  name                          = "platform-cloudtrail"
  s3_bucket_name                = module.default_s3_bucket.bucket
  include_global_service_events = false
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*" # CloudTrail requires the Log Stream wildcard
}

# TODO: Cloud watch log role / policy, etc
# TODO: Cloud Posse metrics - use these vs. reinvent the wheel