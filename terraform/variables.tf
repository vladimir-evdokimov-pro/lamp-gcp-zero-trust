variable "project_id" {
  description = "The GCP Project ID"
  type = string
  default = "lamp-3tier-production"
}

variable "region" {
  description = "The GCP target region"
  type = string
  default = "europe-west9"
}

variable "zone" {
  description = "The GCP target zone"
  type = string
  default = "europe-west9-a"
}