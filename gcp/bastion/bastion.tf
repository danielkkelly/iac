provider "google" {
  credentials = file("~/iac/gcp/service-account.json")
  project     = "terraform-273919"
  region      = "us-east1"
}

data "google_compute_network" "platform_vpc" {
  name = "platform-vpc"
}

data "google_compute_subnetwork" "subnet_bastion" {
  name = "platform-app-subnet-1"
}

resource "google_compute_address" "internal_with_subnet_and_address" {
  name         = "platform-bastion"
  subnetwork   = data.google_compute_subnetwork.subnet_bastion.id
  address_type = "INTERNAL"
  address      = "10.0.2.10"
  region       = "us-east1"
}

resource "google_compute_address" "static" {
  name = "platform-bastion-ipv4-address"
}

data "google_compute_image" "debian_image" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_instance" "bastion" {
  name         = "platform-bastion"
  machine_type = "n1-standard-1"
  zone         = "us-east1-b"

  tags = ["bastion"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet_bastion.self_link
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

output "bastion_public_ip" {
  value = google_compute_address.static.address
}