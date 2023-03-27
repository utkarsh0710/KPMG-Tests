# VPC network
resource "google_compute_network" "ilb_network" {
  name                    = var.vpc.name
  provider                = google-beta
  routing_mode            = var.vpc.routing_mode
  auto_create_subnetworks = var.vpc.force_destroy
}

# block of private IP addresses
resource "google_compute_global_address" "private_ip_block" {
  name         = "${var.vpc.name}-private-ip-block"
  purpose      = var.vpc.purpose
  address_type = var.vpc.address_type
  ip_version   = var.vpc.ip_version
  prefix_length = var.vpc.prefix_length
  network       = google_compute_network.ilb_network.self_link
}

# enable private services access
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.ilb_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

# proxy-only subnet
resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "${var.vpc.name}-proxy-subnet"
  provider      = google-beta
  ip_cidr_range = var.proxy_subnet.ip_cidr_range
  region        = var.location
  purpose       = var.proxy_subnet.purpose
  role          = var.proxy_subnet.role
  network       = google_compute_network.ilb_network.id
}

# backend subnet
resource "google_compute_subnetwork" "ilb_subnet" {
  name          = "${var.vpc.name}-subnet"
  provider      = google-beta
  ip_cidr_range = var.backend_subnet.ip_cidr_range
  region        = var.location
  network       = google_compute_network.ilb_network.id
}

# Random ID generator
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# backend TF state bucket
resource "google_storage_bucket" "bucket1" {
  name = "tfstate-${random_id.bucket_suffix.hex}"
  location = var.location
}

# forwarding rule
resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  name                  = "${var.app_name}-forwarding-rule"
  provider              = google-beta
  region                = var.location
  depends_on            = [google_compute_subnetwork.proxy_subnet]
  ip_protocol           = var.fwd_rule.ip_protocol
  load_balancing_scheme = var.fwd_rule.load_balancing_scheme
  port_range            = var.fwd_rule.port_range
  target                = google_compute_region_target_http_proxy.default.id
  network               = google_compute_network.ilb_network.id
  subnetwork            = google_compute_subnetwork.ilb_subnet.id
  network_tier          = var.fwd_rule.network_tier
}

# HTTP target proxy
resource "google_compute_region_target_http_proxy" "target_http_proxy" {
  name     = "${var.app_name}-target-http-proxy"
  provider = google-beta
  region   = var.location
  url_map  = google_compute_region_url_map.url_map.id
}

# URL map
resource "google_compute_region_url_map" "url_map" {
  name            = "${var.app_name}-regional-url-map"
  provider        = google-beta
  region          = var.location
  default_service = google_compute_region_backend_service.backend_service.id
}

# backend service
resource "google_compute_region_backend_service" "backend_service" {
  name                  = "${var.app_name}-backend-subnet"
  provider              = google-beta
  region                = var.location
  protocol              = var.bck_svc.protocol
  load_balancing_scheme = var.fwd_rule.load_balancing_scheme
  timeout_sec           = var.bck_svc.timeout_sec
  health_checks         = [google_compute_region_health_check.hc.id]
  backend {
    group           = google_compute_region_instance_group_manager.mig.instance_group
    balancing_mode  = var.bck_svc.balancing_mode
    capacity_scaler = var.bck_svc.capacity_scaler
  }
}

# SA for cloud_sql_proxy
resource "google_service_account" "proxy_account" {
  account_id = var.db_sa.account_id
}
resource "google_project_iam_member" "role" {
  role   = var.db_sa.role
  member = "serviceAccount:${google_service_account.proxy_account.email}"
}
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.proxy_account.name
}

# instance template
resource "google_compute_instance_template" "instance_template" {
  name         = "${var.app_name}-mig-template"
  provider     = google-beta
  machine_type = var.ins_tem.machine_type
  tags         = var.ins_tem.tags

  network_interface {
    network    = google_compute_network.ilb_network.id
    subnetwork = google_compute_subnetwork.ilb_subnet.id
  }
  disk {
    source_image = var.ins_tem.source_image
    auto_delete  = var.ins_tem.auto_delete
    boot         = var.ins_tem.boot
  }

  service_account {
    email = google_service_account.proxy_account.email
    scopes = ["cloud-platform"]
  }

}

# health check
resource "google_compute_region_health_check" "hc" {
  name     = "${var.app_name}-hc"
  provider = google-beta
  region   = var.location
  http_health_check {
    port_specification = var.hc_port_spec
  }
}

# MIG
resource "google_compute_region_instance_group_manager" "mig" {
  name     = "${var.app_name}-mig"
  provider = google-beta
  region   = var.location
  version {
    instance_template = google_compute_instance_template.instance_template.id
    name              = "primary"
  }
  base_instance_name = "${var.app_name}-vm"
  target_size        = var.target_size
}

# allow all access from IAP and health check ranges
resource "google_compute_firewall" "fw_iap" {
  name          = "${var.app_name}-fw-allow-iap-hc"
  project       = var.project
  provider      = google-beta
  direction     = var.fw_iap_rules.direction
  network       = google_compute_network.ilb_network.id
  source_ranges = var.fw_iap_rules.source_ranges
  allow {
    protocol = var.fw_iap_rules.protocol
  }
}

# allow http from proxy subnet to backends
resource "google_compute_firewall" "fw_ilb_to_backends" {
  name          = "${var.app_name}-fw-allow-ilb-to-backends"
  project       = var.project
  provider      = google-beta
  direction     = var.fw_ilb_to_backends.direction
  network       = google_compute_network.ilb_network.id
  source_ranges = var.fw_ilb_to_backends.source_ranges
  target_tags   = var.fw_ilb_to_backends.target_tags
  allow {
    protocol = var.fw_ilb_to_backends.protocol
    ports    = var.fw_ilb_to_backends.ports
  }
}

# firewall rule to allow ingress SSH traffic
resource "google_compute_firewall" "allow_ssh" {
  name        = "${var.app_name}-allow-ssh"
  network     = google_compute_network.ilb_network.name
  direction   = var.allow_ssh.direction
  allow {
    protocol = var.allow_ssh.tcp
    ports    = var.allow_ssh.ports
  }
  target_tags = var.allow_ssh.target_tags
}

# DB instance
resource "google_sql_database_instance" "main" {
  name             = "${var.app_name}-db-instance"
  database_version = var.db.database_version
  region           = var.location
  settings {
    tier = var.db.tier
  }
}

resource "google_sql_user" "db_user" {
  name     = var.db.user
  instance = google_sql_database_instance.main.name
  password = var.db.password
}