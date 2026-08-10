output "load_balancer_ip" {
  description = "Public IP for web application access"
  value       = module.load-balancer.lb_ip
}

output "web_vm_private_ip" {
  description = "Private IP of the web instance"
  value       = module.compute.web_vm_ip
}

output "app_vm_private_ip" {
  description = "Private IP of the app instance"
  value       = module.compute.app_vm_ip
}

output "db_psc_endpoint_ip" {
  description = "Private IP of the Private Service Connect endpoint for Cloud SQL"
  value       = module.database.db_private_ip
}

output "secret_id" {
  description = "Secret Manager secret ID/name containing DB credentials"
  value       = module.security.secret_id
}