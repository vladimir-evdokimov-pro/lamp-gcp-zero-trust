variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "network" {
  type = string
}

variable "sb_web_id" {
  type = string
}

variable "sb_app_id" {
  type = string
}

variable "sa_web_email" {
  type = string
}

variable "sa_app_email" {
  type = string
}

variable "machine_type" {
  description = "Type of Machine used for instance configuration"
  type = string
  default = "e2-micro"
}

variable "web_vm_name" {
  description = "Name for Web instance configuration"
  type = string
  default = "web-server1"
}

variable "app_vm_name" {
  description = "Name for App instance configuration"
  type = string
  default = "app-server1"
}

variable "image_boot" {
  description = "Choose image for boot instances"
  type = string
  default = "debian-cloud/debian-12"
}