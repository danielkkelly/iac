locals {
  base_bucket_name = "platform-${var.env}-${var.name}-${random_id.random_s3_index.hex}"
}

/* 
 * Sets up for a secure S3 bucket.  It would be even better if we coudl add a stanza to 
 * a policy to deny all without SSL and to handle the aws_s3_bucket_public_access_block
 * here as well.
 */
resource "random_id" "random_s3_index" {
  byte_length = 4
}

/* 
 * Shows the FedRAMP controls associated with the configuration.  Note that the
 * AC-3, AC-4, AC-5, AC-6, AC-14 compliance is enforeced in policy.  These 
 * policies are specified in the caller of this module but should require SSL
 * in all cases.  Audited via Security Hub and AWS Config CMMC3 conformance pack.
 */
resource "aws_s3_bucket" "s3_bucket" {
  bucket        = local.base_bucket_name
  acl           = "private"
  force_destroy = true

  // CM-2, SI-7
  versioning {
    enabled = var.versioning_enabled
  }

  // AU-2, AU-3, AU-9, AU-11
  logging {
    target_bucket = aws_s3_bucket.s3_logging_bucket.id
    target_prefix = var.name
  }

  // AU-9, CP-6
  // replication_configuration {}

  // SC-13, SC-28
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

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

resource "aws_s3_bucket_public_access_block" "s3_logging_bucket_pab" {
  bucket = aws_s3_bucket.s3_logging_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}