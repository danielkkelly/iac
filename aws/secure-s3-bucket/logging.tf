resource "aws_s3_bucket" "s3_logging_bucket" {
  bucket        = "${local.base_bucket_name}-logging"
  acl           = "log-delivery-write"
  force_destroy = true

  // CM-2, SI-7
  versioning {
    enabled = var.versioning_enabled
  }

 logging {
    target_bucket = "${local.base_bucket_name}-logging"
    target_prefix = "${var.name}-logging"
  }

  // SC-13, SC-28
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  // AU.3.049
  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }

  // SI-12
  lifecycle_rule { 
    enabled = true

    transition {
      days = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_policy" "logging_bucket_policy" {
  bucket = aws_s3_bucket.s3_logging_bucket.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Require SSL",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "*",
            "Resource": "${aws_s3_bucket.s3_logging_bucket.arn}/*",
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

resource "aws_s3_bucket_public_access_block" "s3_logging_bucket_pab" {
  bucket = aws_s3_bucket.s3_logging_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.logging_bucket_policy]
}