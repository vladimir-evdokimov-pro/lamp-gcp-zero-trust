# Cloud SQL MySQL + Private Service Connect (PSC)

resource "google_sql_database_instance" "db" {
  name = var.db_name
  database_version = var.db_version
  region = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      psc_config {
        psc_enabled = true
        allowed_consumer_projects = [ var.project_id ]
      }
      ipv4_enabled = false
    }
    availability_type = "REGIONAL"

    user_labels = var.db_labels

    backup_configuration {
      enabled = true
      binary_log_enabled = true
    }

  }

  deletion_protection = false
}

resource "google_compute_address" "psc_ip" {
  name = var.psc_ip_name
  project = var.project_id
  subnetwork = var.subnet_id
  region = var.region
  address_type = "INTERNAL"
  address = var.psc_ip_address
}

resource "google_compute_forwarding_rule" "fr_psc_link" {
  name = var.fr_psc_link_name
  project = var.project_id
  region = var.region
  network = var.vpc_id
  subnetwork = var.subnet_id
  ip_address = google_compute_address.psc_ip.self_link
  target = google_sql_database_instance.db.psc_service_attachment_link
  load_balancing_scheme = ""
}

resource "google_sql_database" "pmadb" {
  name = var.pmadb_name
  instance = google_sql_database_instance.db.name
}

resource "google_sql_user" "pmausr" {
  name = var.pmausr_name
  instance = google_sql_database_instance.db.name
  password = var.db_password
}