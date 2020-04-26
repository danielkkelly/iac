
provider "google" {
  project     = var.project
  region      = var.region
}

resource "google_project_service" "service" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "oslogin.googleapis.com",
    "cloudmonitoring.googleapis.com"
  ])

  service = each.key

  project            = var.project
  disable_on_destroy = false
}

resource "google_compute_project_metadata_item" "oslogin" {
  project = var.project
  key     = "enable-oslogin"
  value   = "TRUE"

  depends_on = [
    google_project_service.service
  ]
}

/*
 * There is also a role for non admin users that could be applied as
 * a separate step.  This provides sudo
 */
resource "google_project_iam_binding" "oslogin-admin-users" {
  role = "roles/compute.osAdminLogin"

  members = [
    "user:daniel_k_kelly@yahoo.com"
  ]
}

resource "google_os_login_ssh_public_key" "ssh_key" {
  user = "daniel_k_kelly@yahoo.com"
  key  = file("~/iac/keys/dan.pub")
}