provider "aws" {
  region  = var.region
  profile = var.env
}

data "aws_caller_identity" "current" {}