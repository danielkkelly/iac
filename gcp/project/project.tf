variable "project_name" {}
variable "billing_account" {}
variable "org_id" {}
variable "region" {}
variable "env" {}

provider "google" {
  region = var.region
}

resource "random_id" "id" {
  byte_length = 4
  prefix      = "${var.project_name}-"
}

resource "google_project" "project" {
  name                = var.project_name
  project_id          = random_id.id.hex
  billing_account     = var.billing_account
  org_id              = var.org_id
  auto_create_network = false
}

resource "google_project_service" "service" {
  for_each = toset([
    "compute.googleapis.com"
  ])

  service = each.key

  project            = google_project.project.project_id
  disable_on_destroy = false
}

output "project_name" {
  value = google_project.project.name
}

output "project_id" {
  value = google_project.project.project_id
}