variable "project_id" {
  description = "The GCP Project ID"
  type = string
}

variable "vpc_id" {
  description = "The GCP target vpc"
  type = string
}

variable "subnet_id" {
  description = "The GCP target subnetwork"
  type = string
}

variable "region" {
  description = "The GCP target region"
  type = string
}

variable "zone" {
  description = "The GCP target zone"
  type = string
}

variable "ig_name" {
  description = "Name for Instance Group Unmanaged"
  type = string
  default = "ig-pma"
}

variable "web_instance_self_link" {
  description = "Self link of the Web VM instance"
  type        = string
}

variable "hc_name" {
  description = "Name for Health-Check of load balancer"
  type = string
  default = "hc-lb-pma"
}

variable "bs_name" {
  description = "Name for Backend Service of load balancer"
  type = string
  default = "bs-pma"
}

variable "um_name" {
  description = "Name for URL MAP of load balancer"
  type = string
  default = "um-pma"
}

variable "http_proxy_name" {
  description = "Name for Target HTTP Proxy of load balancer"
  type = string
  default = "http-proxy-pma"
}

variable "lb_ip_name" {
  description = "Name for IP address for load balancer"
  type = string
  default = "lb-ip-pma"
}

variable "gfr_name" {
  description = "Name for Global Forwarding Rule for load balancer"
  type = string
  default = "gfr-pma"
}