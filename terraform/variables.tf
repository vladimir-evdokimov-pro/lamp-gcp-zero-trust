variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The GCP target region"
  type        = string
}

variable "zone" {
  description = "The GCP target zone"
  type        = string
}

variable "gcp_apis" {
  description = "List of APIs to enable for realize this configuration"
  type        = set(string)
  default = [
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "servicenetworking.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com"
  ]
}

variable "username" {
  description = "Username for ssh key metadata provision"
  type        = string
}