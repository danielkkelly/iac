terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [ aws.default, aws.replica ]
    }
  }
}

locals {
  bucket_name_replica = "${var.bucket_name}-replica"
}

resource "aws_s3_bucket" "replication_bucket" {
  provider      = aws.replica
  bucket        = local.bucket_name_replica
  force_destroy = true

  versioning {
    enabled = true
  }

  // AU.3.049
  dynamic "object_lock_configuration" {
    for_each = var.object_lock_enabled == false ? toset([]) : toset([1])

    content {
      object_lock_enabled = "Enabled"
    }
  }

  // SC-13, SC-28
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "replication_bucket_policy" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replication_bucket.id
  policy   = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Require SSL",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "*",
            "Resource": "${aws_s3_bucket.replication_bucket.arn}/*",
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

resource "aws_s3_bucket_public_access_block" "s3_replication_bucket_pab" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replication_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.replication_bucket_policy]
}