# VPC, Subnets, Cloud Router, Cloud NAT

resource "google_compute_network" "vpc" {
  name = var.vpc_name

  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "sb_web" {
  name = var.sb_web_name

  ip_cidr_range = var.cidr_range_sb_web
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "sb_app" {
  name = var.sb_app_name

  ip_cidr_range = var.cidr_range_sb_app
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "sb_data" {
  name = var.sb_data_name

  ip_cidr_range = var.cidr_range_sb_data
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "sb_proxy" {
  name = var.sb_proxy_name

  ip_cidr_range = var.cidr_range_sb_proxy
  region        = var.region
  network       = google_compute_network.vpc.id

  purpose = "REGIONAL_MANAGED_PROXY"
  role    = "ACTIVE"
}

resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}