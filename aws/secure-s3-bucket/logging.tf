module "s3_logging_bucket_replica" {
  count               = var.logging_enabled ? 1 : 0
  source              = "../secure-s3-replica"
  env                 = var.env
  bucket_name         = local.bucket_name_logging
  object_lock_enabled = var.object_lock_enabled
  providers = {
    aws.default = aws.default
    aws.replica = aws.replica
  }
}

resource "aws_s3_bucket" "s3_logging_bucket" {
  count         = var.logging_enabled ? 1 : 0
  provider = aws.default
  bucket        = local.bucket_name_logging
  acl           = "log-delivery-write"
  force_destroy = true

  // CM-2, SI-7
  versioning {
    enabled = var.versioning_enabled
  }

  logging {
    target_bucket = local.bucket_name_logging
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
  dynamic "object_lock_configuration" {
    for_each = var.object_lock_enabled == false ? toset([]) : toset([1])

    content {
      object_lock_enabled = "Enabled"
    }
  }

  // SI-12
  lifecycle_rule {
    enabled = true

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  // AU-9, CP-6
  replication_configuration {
    role = module.s3_bucket_replica[0].replication_role_arn

    rules {
      id     = local.bucket_name_logging
      status = "Enabled"

      destination {
        bucket        = module.s3_logging_bucket_replica[0].arn
        storage_class = "GLACIER"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "logging_bucket_policy" {
  count  = var.logging_enabled ? 1 : 0
  provider = aws.default
  bucket = aws_s3_bucket.s3_logging_bucket[0].id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Require SSL",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "*",
            "Resource": "${aws_s3_bucket.s3_logging_bucket[0].arn}/*",
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
  count  = var.logging_enabled ? 1 : 0
  provider = aws.default
  bucket = aws_s3_bucket.s3_logging_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.logging_bucket_policy]
}