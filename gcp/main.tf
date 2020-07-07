provider "google" {
  region      = var.region
}

provider "google-beta" {
  region      = var.region
}

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

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = module.project.project_id
  name                       = "platform-gke"
  region                     = var.region
  zones                      = ["us-east1-b", "us-east1-c"]
  network                    = module.network.network_name
  subnetwork                 = module.network.subnet_app_1_name
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = false
  horizontal_pod_autoscaling = true
  network_policy             = true
  enable_private_endpoint    = false
  enable_private_nodes       = true

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 1
      max_count          = 2
      local_ssd_count    = 0
      disk_size_gb       = 10
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      initial_node_count = 2
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "platform-gke-node-pool"
    }
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}