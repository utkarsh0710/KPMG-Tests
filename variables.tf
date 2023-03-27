variable "project" {
    type = string
    default = "project_name"
    description = "name of the GCP project."
}

variable "location" {
  type = string
  default = "us-east1"
  description = "location of the bucket"
}

variable "app_name" {
  type = string
  defadefault = "3_tier"  
}

variable "vpc" {
  type = object({
    force_destroy = bool
    routing_mode = string
    name      = string
    purpose      = string
    address_type = string
    ip_version   = string
    prefix_length = number
  })
  default = {
    name = "dev-vpc"
    force_destroy = false
    routing_mode  = "GLOBAL"
    purpose      = "VPC_PEERING"
    address_type = "INTERNAL"
    ip_version   = "IPV4"
    prefix_length = 20
  }
}

variable "proxy_subnet" {
  type = object({
    ip_cidr_range = string
    purpose = string
    role = string
  })
  default = {
    ip_cidr_range = "10.0.0.0/24"
    purpose = "INTERNAL_HTTPS_LOAD_BALANCER"
    role = "ACTIVE"
  }
}

variable "backend_subnet" {
  ttype = object({
    ip_cidr_range = string
  })
  default = {
    ip_cidr_range = "10.0.1.0/24"
  }
}

variable "fwd_rule" {
  type = object({
    ip_protocol = string
    load_balancing_scheme = string
    port_range = string
    network_tier = string
  })
  default = {
    ip_protocol = "TCP"
    load_balancing_scheme = "INTERNAL_MANAGED"
    port_range = "80"
    network_tier = "PREMIUM"
  }
}

variable "bck_svc" {
  type = object({
    protocol = string
    balancing_mode = string
    timeout_sec = number
    capacity_scaler = number
  })
  default = {
    protocol = "HTTP"
    balancing_mode = "UTILIZATION"
    timeout_sec = 10
    capacity_scaler = 1.0
  }
}

variable "ins_tem" {
  type = object({
    machine_type = string
    tags = list(string)
    auto_delete = bool
    boot = bool
    source_image = string
  })
  default = {
    machine_type = "e2-small"
    tags = ["http-server", "ssh-enabled"]
    auto_delete = false
    boot = false
    source_image = "debian-cloud/debian-10"
  }
}

variable "hc_port_spec" {
  type = string
  default = "USE_SERVING_PORT"
}

variable "target_size" {
  type = number
  default = 3
}

variable "fw_iap_rules" {
  type = object({
    direction = string
    source_ranges = list(string)
    protocol = string
  })
  default = {
    direction = "INGRESS"
    source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
    protocol = "tcp"
  }
}

variable "fw_ilb_to_backends" {
  type = object({
    direction = string
    source_ranges = list(string)
    target_tags   = list(string)
    ports   = list(string)
    protocol = string
  })
  default = {
    direction = "INGRESS"
    source_ranges = ["10.0.0.0/24"]
    protocol = "tcp"
    target_tags   = ["http-server"]
    ports = ["80", "443", "8080"]
  }
}

variable "allow_ssh" {
  type = object({
    direction = string
    source_ranges = list(string)
    target_tags   = list(string)
    ports   = list(string)
    protocol = string
  })
  default = {
    direction = "INGRESS"
    protocol = "tcp"
    target_tags   = ["ssh-enabled"]
    ports = ["22"]
  }
}

variable "db" {
  type = object({
    database_version = string
    tier = string
    user = string
    password = string
  })
  default = {
    tier = "db-n1-standard-1"
    database_version = "MYSQL_5_7"
    user = "test1"
    password = "test123"
  }
}

variable "db_sa" {
  type = object({
    account_id = string
    role = string
  })
  default = {
    account_id = "cloud-sql-proxy"
    role = "roles/cloudsql.editor"
  }
}