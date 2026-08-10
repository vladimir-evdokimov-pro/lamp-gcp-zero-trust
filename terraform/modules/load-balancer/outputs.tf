output "lb_ip" {
  description = "Return External IP address of load balancer"
  value = google_compute_global_address.lb_ip.address
}