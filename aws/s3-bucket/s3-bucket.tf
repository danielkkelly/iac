resource "random_id" "random_s3_index" {
  byte_length = 4
}

# TODO: Better than random?
#data "aws_caller_identity" "current" {}
#${data.aws_caller_identity.current.account_id}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "platform-${var.name}-${var.env}-${random_id.random_s3_index.hex}"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = var.versioning_enabled
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}