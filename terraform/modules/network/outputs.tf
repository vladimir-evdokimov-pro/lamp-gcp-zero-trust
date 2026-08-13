output "vpc_id" {
  description = "The ID of the created VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the created VPC"
  value       = google_compute_network.vpc.name
}

output "sb_web_id" {
  description = "The ID of the Web subnet"
  value       = google_compute_subnetwork.sb_web.id
}

output "sb_app_id" {
  description = "The ID of the App subnet"
  value       = google_compute_subnetwork.sb_app.id
}

output "sb_data_id" {
  description = "The ID of the Data subnet"
  value       = google_compute_subnetwork.sb_data.id
}

output "sb_proxy_id" {
  description = "The ID of the Proxy subnet"
  value       = google_compute_subnetwork.sb_proxy.id
}