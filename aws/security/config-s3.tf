provider "aws" {
  alias  = "replica"
  region = var.replication_region
  profile = var.env
}

module "config_s3_bucket" {
  source = "../secure-s3-bucket"
  name   = "config"
  env    = var.env
  providers = {
    aws.default = aws
    aws.replica = aws.replica
  }
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = module.config_s3_bucket.id

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
      "Resource": "${module.config_s3_bucket.arn}",
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
      "Resource": "${module.config_s3_bucket.arn}/*",
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
      "Resource": "${module.config_s3_bucket.arn}/*",
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

# Needs to be here due to dependency on the policy, otherwise could modularize
resource "aws_s3_bucket_public_access_block" "s3_bucket_pab" {
  bucket = module.config_s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.config_bucket_policy]
}