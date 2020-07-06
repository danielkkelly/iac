# TODO: create public subnet, NAT gateway, variables, routes
# delete default network per Google recommendations

provider "google" {
  region = var.region
}

resource "google_compute_network" "platform_vpc" {
  name                    = "platform-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_app_1" {
  name          = "platform-app-subnet-1"
  ip_cidr_range = var.cidr_block_subnet_app_1
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.platform_vpc.self_link
}

resource "google_compute_subnetwork" "subnet_app_2" {
  name          = "platform-app-subnet-2"
  ip_cidr_range = var.cidr_block_subnet_app_2
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.platform_vpc.self_link
}


output "network_id" {
  value = google_compute_network.platform_vpc.self_link
}

output "network_name" {
  value = google_compute_network.platform_vpc.name
}

output "subnet_app_1_id" {
  value = google_compute_subnetwork.subnet_app_1.self_link
}

output "subnet_app_1_name" {
  value = google_compute_subnetwork.subnet_app_1.name
}