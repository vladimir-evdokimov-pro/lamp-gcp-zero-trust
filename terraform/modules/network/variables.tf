variable "project_id" {
  description = "The GCP Project ID"
  type = string
}

variable "region" {
  description = "The GCP target region"
  type = string
}

variable "vpc_name" {
  description = "The VPC name"
  type = string
  default = "vpc-lamp-prod-ew9"
}

variable "sb_web_name" {
  description = "Web server VM (Apache / Reverse proxy)"
  type = string
  default = "sb-web-prod-ew9"
}

variable "cidr_range_sb_web" {
  description = "IP range for web subnet configuration"
  type = string
  default = "10.0.1.0/24"
}

variable "sb_app_name" {
  description = "Application VMs (PHP-FPM, phpMyAdmin)"
  type = string
  default = "sb-app-prod-ew9"
}

variable "cidr_range_sb_app" {
  description = "IP range for app subnet configuration"
  type = string
  default = "10.0.2.0/24"
}

variable "sb_data_name" {
  description = "Private Service Connect (PSC) endpoints for Cloud SQL"
  type = string
  default = "sb-db-prod-ew9"
}

variable "cidr_range_sb_data" {
  description = "IP range for data subnet configuration"
  type = string
  default = "10.0.3.0/24"
}

variable "sb_proxy_name" {
  description = "GCP requirement for the external HTTP(S) load balancer (Envoy)"
  type = string
  default = "sb-proxy-prod-ew9"
}

variable "cidr_range_sb_proxy" {
  description = "IP range for proxy subnet configuration"
  type = string
  default = "10.0.10.0/23"
}

variable "router_name" {
  description = "The GCP router name"
  type = string
  default = "cr-lamp-prod-ew9"
}

variable "nat_name" {
  description = "The GCP NAT name"
  type = string
  default = "nat-lamp-prod-ew9"
}