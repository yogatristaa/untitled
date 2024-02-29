# main.tf
variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  description = "Region name"
}

variable "key_dir" {
  description = "Dir of Service Account JSON"
}

provider "google" {
  credentials = file(var.key_dir)
  project     = var.project_id
  region      = var.region
}

# VPC Creation
# resource "google_compute_network" "vpc" {
#   name                    = "gke-vpc-staging"
#   auto_create_subnetworks = "false"
# }

# Subnet Creation
# resource "google_compute_subnetwork" "subnet" {
#   name          = "gke-vpc-staging-subnet"
#   region        = var.region
#   network       = "vpc-staging"
#   ip_cidr_range = "10.10.0.0/24"
# }

resource "google_container_cluster" "gke_cluster" {
  name     = "staging-cluster-test"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1
  # network    = google_compute_network.vpc.name
  # subnetwork = google_compute_subnetwork.subnet.name
  network    = "vpc-staging"
  subnetwork = "gke-vpc-staging-subnet"

  #Delete Protection Option
  deletion_protection = false

  private_cluster_config {
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "10.10.1.0/28"
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = true
    }
  }
}

resource "google_container_node_pool" "node_worker_1" {
  # Worker 1 node pool
    name               = "worker-pool-1"
    location           = var.region
    cluster            = google_container_cluster.gke_cluster.name
    node_count         = 1

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "${var.project_id}-gke"
    }

    # preemptible  = true
    machine_type = "n1-standard-2"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Create a proxy-only subnet for Internal Gateway
# resource "google_compute_subnetwork" "test-subnet" {
#   name          = "test-subnet"
#   region        = var.region
#   network       = "vpc-staging"
#   ip_cidr_range = "10.20.0.0/23"
#   purpose       = "REGIONAL_MANAGED_PROXY"
#   role          = "ACTIVE"
# }

#Create Router
resource "google_compute_router" "router" {
  name    = "${google_container_cluster.gke_cluster.name}-router"
  region  = var.region
  # network = google_compute_network.vpc.name
  network    = "vpc-staging"
  
}

#Create Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "${google_container_cluster.gke_cluster.name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# data "google_compute_firewall" "master_fw" {
#   name = google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate
# }

# Save relevant attributes to variables
# locals {
#   firewall_rule_name    = data.google_compute_firewall.master_fw.name
#   firewall_rule_network = data.google_compute_firewall.master_fw.network
# }

#Modify Firewall Rule
# resource "google_compute_firewall" "existing_firewall_rule" {
#   name    = data.google_compute_firewall.master_fw.name
#   network = google_compute_network.vpc.name

#   allow {
#     protocol = "tcp"
#     ports    = ["80", "443", "9443", "15017"]  
#   }

#   source_ranges = ["0.0.0.0/0"]   #cari tau
# }

# module "gcloud" {
#   source  = "terraform-google-modules/gcloud/google"
#   version = "~> 3.0"

#   platform              = "linux"
#   additional_components = ["kubectl", "beta"]

#   create_cmd_entrypoint = "gcloud"
#   # Module does not support explicit dependency
#   # Enforce implicit dependency through use of local variable
#   create_cmd_body = "container clusters get-credentials ${local.cluster_name} --zone=${var.region} --project=${var.gcp_project_id}"
# }

# # Apply YAML kubernetes-manifest configurations
# resource "null_resource" "apply_deployment" {
#   provisioner "local-exec" {
#     interpreter = ["bash", "-exc"]
#     command     = "kubectl apply -k ${var.filepath_manifest} -n ${var.namespace}"
#   }

#   depends_on = [
#     module.gcloud
#   ]
# }