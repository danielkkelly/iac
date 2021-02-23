/* 
 * Create an S3 bucket for logs and attach the appropriate policy.  Note the variable for 
 * the region-specific load balancer account.  More inforomation available in the docs.
 * https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
 */
module "alb_s3_bucket" {
  source     = "../secure-s3-bucket"
  name       = "lb-bucket"
  env        = var.env
}

resource "aws_s3_bucket_policy" "alb_bucket_policy" {
  bucket = module.alb_s3_bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.alb_account[var.region]}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "${module.alb_s3_bucket.arn}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${module.alb_s3_bucket.arn}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${module.alb_s3_bucket.arn}"
    },
    {
      "Sid": "Require SSL",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "${module.alb_s3_bucket.arn}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
EOF
}

# Needs to be here due to dependency on the policy, otherwise could modularize
resource "aws_s3_bucket_public_access_block" "s3_bucket_pab" {
  bucket = module.alb_s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.alb_bucket_policy]
}