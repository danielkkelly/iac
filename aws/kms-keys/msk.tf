module "msk_kms_key" {
  source = "../kms-key"
  env    = var.env
  name   = "msk"
}