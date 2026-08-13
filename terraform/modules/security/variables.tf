variable "project_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "sa_terraform_name" {
  description = "Service Account used to provision GCP resources"
  type        = string
  default     = "sa-terraform"
}

variable "sa_ansible_name" {
  description = "Service Account used for dynamic inventory and SSH connection"
  type        = string
  default     = "sa-ansible"
}

variable "sa_web_name" {
  description = "Service Account used for Web instance and communication"
  type        = string
  default     = "sa-web"
}

variable "sa_app_name" {
  description = "Service Account used for App instance and communication"
  type        = string
  default     = "sa-app"
}

variable "role_sa_terraform" {
  description = "List of roles required by the Terraform Service Account"
  type        = set(string)
  default = [
    "roles/compute.admin",
    "roles/cloudsql.admin",
    "roles/secretmanager.admin",
    "roles/storage.admin"
  ]
}

variable "role_sa_ansible" {
  description = "List of roles required by the Ansible Service Account"
  type        = set(string)
  default = [
    "roles/compute.viewer",
    "roles/iap.tunnelResourceAccessor",
    "roles/compute.osLogin"
  ]
}

variable "role_sa_web" {
  description = "List of roles required by the Web Service Account"
  type        = set(string)
  default = [
    "roles/logging.logWriter"
  ]
}

variable "role_sa_app" {
  description = "List of roles required by the App Service Account"
  type        = set(string)
  default = [
    "roles/logging.logWriter",
    "roles/secretmanager.secretAccessor"
  ]
}

variable "fw_ssh_iap_name" {
  description = "Name of Firewall rule for ssh connection with iap"
  type        = string
  default     = "fw-allow-ssh-to-iap"
}

variable "fw_lb_name" {
  description = "Name of Firewall rule for load balancer configuration"
  type        = string
  default     = "fw-allow-lb-http-https"
}

variable "fw_web_app_name" {
  description = "Name of Firewall rule to accept communication between web instance and app instance"
  type        = string
  default     = "fw-allow-web-app"
}

variable "fw_app_db_name" {
  description = "Name of Firewall rule to accept communication between app instance and database"
  type        = string
  default     = "fw-allow-app-db"
}

variable "sm_db_name" {
  description = "Name for Secret Manager utilization for save database password"
  type        = string
  default     = "database-password"
}