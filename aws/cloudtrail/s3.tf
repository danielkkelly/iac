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
            "Sid": "AWSCloudTrailAclCheck20150319",
            "Effect": "Allow",
            "Principal": { "Service": "cloudtrail.amazonaws.com" },
            "Action": "s3:GetBucketAcl",
            "Resource": "${module.default_s3_bucket.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite20150319",
            "Effect": "Allow",
            "Principal": { "Service": "cloudtrail.amazonaws.com" },
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