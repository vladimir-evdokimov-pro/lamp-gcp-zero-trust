# External HTTP Application Load Balancer

resource "google_compute_instance_group" "ig" {
  name = var.ig_name
  zone = var.zone
  network = var.vpc_id

  instances = [ 
    var.web_instance_self_link
  ]

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "hc" {
  name = var.hc_name
  check_interval_sec = 10
  timeout_sec = 5
  healthy_threshold = 2
  unhealthy_threshold = 3

  http_health_check {
    port = 80
    request_path = "/healthz"
  }
}

resource "google_compute_backend_service" "bs" {
  name = var.bs_name
  protocol = "HTTP"
  port_name = "http"
  timeout_sec = 30
  health_checks = [ google_compute_health_check.hc.id ]
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_instance_group.ig.id
    balancing_mode = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  connection_draining_timeout_sec = 300

  log_config {
    enable = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "um" {
  name = var.um_name
  default_service = google_compute_backend_service.bs.id
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name = var.http_proxy_name
  url_map = google_compute_url_map.um.id
}

resource "google_compute_global_address" "lb_ip" {
  name = var.lb_ip_name
}

resource "google_compute_global_forwarding_rule" "gfr" {
  name = var.gfr_name
  target = google_compute_target_http_proxy.http_proxy.id
  ip_address = google_compute_global_address.lb_ip.id
  port_range = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}