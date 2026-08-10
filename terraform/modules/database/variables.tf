variable "project_id" {
  type = string
}

variable "vpc_id" {
  description = "ID of the VPC Network"
  type = string
}

variable "region" {
  type = string
}

variable "subnet_id" {
  description = "ID of the Subnet hosting the PSC Endpoint"
  type        = string
}

variable "db_name" {
  description = "Name for SQL instance"
  type = string
  default = "db-pma"
}

variable "db_version" {
  description = "Define MySQL version for instance configuration"
  type = string
  default = "MYSQL_8_4"
}

variable "db_labels" {
  description = "Resource labels to apply to app resources"
  type = map(string)
  default = {
    "role" = "db"
    "env" = "prod"
    "tier" = "database"
    "managed_by" = "terraform"
  }
}

variable "psc_ip_name" {
  description = "Name for IP address to PSC"
  type = string
  default = "ip-psc-sql"
}

variable "psc_ip_address" {
  description = "IP address for PSC endpoint"
  type = string
  default = null
}

variable "fr_psc_link_name" {
  description = "Name for forwarding rule about PSC configuration"
  type = string
  default = "fr-psc-sql"
}

variable "pmadb_name" {
  description = "Name for PMA Database configuration"
  type = string
  default = "pma-db"
}

variable "pmausr_name" {
  description = "Name for PMA Database User connection"
  type = string
  default = "pma-user"
}

variable "db_password" {
  description = "Database password for associate this to App instance"
  type = string
  sensitive = true
}