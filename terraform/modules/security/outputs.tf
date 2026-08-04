output "sa_terraform_email" {
  description = "Email of Terraform Service Account"
  value = google_service_account.sa_terraform.email
}

output "sa_ansible_email" {
  description = "Email of Ansible Service Account"
  value = google_service_account.sa_ansible.email
}

output "sa_web_email" {
  description = "Email of Web Service Account"
  value = google_service_account.sa_web.email
}

output "sa_app_email" {
  description = "Email of App Service Account"
  value = google_service_account.sa_app.email
}

output "secret_id" {
  description = "ID about secret for Ansible usage"
  value = google_secret_manager_secret.sm_db.secret_id
}