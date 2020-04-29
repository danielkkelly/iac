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
  source          = "./bastion"
  region          = var.region
  project_id      = module.project.project_id
  env             = var.env
  network_id      = module.network.network_id
  subnet_app_1_id = module.network.subnet_app_1_id
}

module cloud_sql {
  source     = "./cloud-sql"
  region     = var.region
  project_id = module.project.project_id
  env        = var.env
  network_id = module.network.network_id
  bastion_ip = module.bastion.private_ip
}

module private_dns {
  source             = "./private-dns"
  region             = var.region
  project_id         = module.project.project_id
  network_id = module.network.network_id
  env                = var.env
  private_ip_bastion = module.bastion.private_ip
  private_ip_mysql   = module.cloud_sql.private_ip
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

output "bastion_private_ip" {
  value = module.bastion.private_ip
}

output "mysql_private_ip" {
  value = module.cloud_sql.private_ip
}