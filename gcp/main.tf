module "project" {
  source          = "./project"
  project_name    = "${var.project_name}-${var.env}"
  billing_account = var.billing_account
  org_id          = var.org_id
  region          = var.region
  env             = var.env
}

module "network" {
  source                  = "./network"
  project_name            = module.project.project_name
  project_id              = module.project.project_id
  region                  = var.region
  env                     = var.env
  cidr_block_subnet_app_1 = var.cidr_block_subnet_app_1
  cidr_block_subnet_app_2 = var.cidr_block_subnet_app_2
}

module "bastion" {
  source     = "./bastion"
  region     = var.region
  project_id = module.project.project_id
  env        = var.env
}

output "project_name" {
  value = module.project.project_name
}

output "project_id" {
  value = module.project.project_id
}

output "bastion_instance_id" {
    value = module.bastion.instance_id
}
output "bastion_public_ip" {
  value = module.bastion.public_ip
}