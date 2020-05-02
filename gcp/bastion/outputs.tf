output "instance_id" {
  value = google_compute_instance.bastion.self_link
}

output "public_ip" {
  value = google_compute_address.static.address
}

output "private_ip" {
  value = google_compute_address.internal_with_subnet_and_address.address
}