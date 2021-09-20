locals {
  bucket_name         = "platform-${var.env}-${var.name}-${random_id.random_s3_index.hex}"
  bucket_name_logging = "${local.bucket_name}-logging"
}

/* 
 * Sets up for a secure S3 bucket.  It would be even better if we coudl add a stanza to 
 * a policy to deny all without SSL and to handle the aws_s3_bucket_public_access_block
 * here as well.
 */
resource "random_id" "random_s3_index" {
  byte_length = 4
}

module "s3_bucket_replica" {
  source              = "../secure-s3-replica"
  bucket_name         = local.bucket_name
  object_lock_enabled = var.object_lock_enabled
}

/* 
 * Shows the FedRAMP controls associated with the configuration.  Note that the
 * AC-3, AC-4, AC-5, AC-6, AC-14 compliance is enforeced in policy.  These 
 * policies are specified in the caller of this module but should require SSL
 * in all cases.  Audited via Security Hub and AWS Config CMMC L3 conformance pack.
 */
resource "aws_s3_bucket" "s3_bucket" {
  bucket        = local.bucket_name
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
    role = module.s3_bucket_replica.replication_role_arn

    rules {
      id     = local.bucket_name
      status = "Enabled"

      destination {
        bucket        = module.s3_bucket_replica.arn
        storage_class = "GLACIER"
      }
    }
  }
}