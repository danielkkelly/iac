provider "aws" {
  region  = var.region
  profile = var.env
}

resource "aws_ses_domain_identity" "domain_identity" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "domain_dkim" {
  domain = aws_ses_domain_identity.domain_identity.domain
}