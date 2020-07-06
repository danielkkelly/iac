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