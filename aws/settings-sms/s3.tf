module "delivery_status_s3_bucket" {
  source = "../secure-s3-bucket"
  name   = var.usage_report_s3_bucket
  env    = var.env
  providers = {
    aws.default = aws.default
    aws.replica = aws.replica
  }
}

data "aws_iam_policy_document" "delivery_status_bucket_policy" {
  policy_id = "sns-sms-daily-usage-policy"

  statement {
    sid       = "AllowPutObject"
    actions   = ["s3:PutObject"]
    resources = ["${module.delivery_status_s3_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }

  statement {
    sid       = "AllowGetBucketLocation"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.delivery_status_s3_bucket.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }

  statement {
    sid       = "AllowListBucket"
    actions   = ["s3:ListBucket"]
    resources = [module.delivery_status_s3_bucket.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }

  statement {
    sid    = "Require SSL"
    effect = "Deny"

    actions   = ["*"]
    resources = ["${module.delivery_status_s3_bucket.arn}/*"]
    
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "delivery_status_bucket_policy" {
  bucket = module.delivery_status_s3_bucket.bucket
  policy = data.aws_iam_policy_document.delivery_status_bucket_policy.json
}

# Needs to be here due to dependency on the policy, otherwise could modularize
resource "aws_s3_bucket_public_access_block" "s3_bucket_pab" {
  bucket = module.delivery_status_s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.delivery_status_bucket_policy]
}