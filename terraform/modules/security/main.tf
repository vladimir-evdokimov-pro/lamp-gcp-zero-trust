# Service Accounts, Rules Firewall, Secret Manager, WIF

resource "google_service_account" "sa_terraform" {
  account_id = var.sa_terraform_name
  display_name = var.sa_terraform_name
}

resource "google_service_account" "sa_ansible" {
  account_id = var.sa_ansible_name
  display_name = var.sa_ansible_name
}

resource "google_service_account" "sa_web" {
  account_id = var.sa_web_name
  display_name = var.sa_web_name
}

resource "google_service_account" "sa_app" {
  account_id = var.sa_app_name
  display_name = var.sa_app_name
}

resource "google_project_iam_member" "role_sa_tf" {
  for_each = toset(var.role_sa_terraform)

  project = var.project_id
  role = each.value
  member = "serviceAccount:${google_service_account.sa_terraform.email}"
}

resource "google_project_iam_member" "role_sa_ans" {
  for_each = toset(var.role_sa_ansible)

  project = var.project_id
  role = each.value
  member = "serviceAccount:${google_service_account.sa_ansible.email}"
}

resource "google_project_iam_member" "role_sa_web" {
  for_each = toset(var.role_sa_web)
  
  project = var.project_id
  role = each.value
  member = "serviceAccount:${google_service_account.sa_web.email}"
}

resource "google_project_iam_member" "role_sa_app" {
  for_each = toset(var.role_sa_app)

  project = var.project_id
  role = each.value
  member = "serviceAccount:${google_service_account.sa_app.email}"
}

resource "google_compute_firewall" "fw_ssh_iap" {
  name = var.fw_ssh_iap_name
  network = var.vpc_id

  description = "IAP flow (secure SSH without a public IP)"

  direction = "INGRESS"

  source_ranges = [ "35.235.240.0/20" ]

  target_service_accounts = [
    google_service_account.sa_web.email,
    google_service_account.sa_app.email
  ]

  allow {
    protocol = "tcp"
    ports = [ "22" ]
  }

}

resource "google_compute_firewall" "fw_lb" {
  name = var.fw_lb_name
  network = var.vpc_id
  description = "Allow Load Balancer and Health Checks to Web"
  direction = "INGRESS"

  source_ranges = [ "10.0.10.0/23", "130.211.0.0/22", "35.191.0.0/16" ]

  target_service_accounts = [ 
    google_service_account.sa_web.email
  ]

  allow {
    protocol = "tcp"
    ports = [ "80", "443" ]
  }
}

resource "google_compute_firewall" "fw_web_app" {
  name = var.fw_web_app_name
  network = var.vpc_id
  description = "Allow communication from Web to App"
  direction = "INGRESS"

  source_service_accounts = [ 
    google_service_account.sa_web.email
  ]

  target_service_accounts = [ 
    google_service_account.sa_app.email
  ]

  allow {
    protocol = "tcp"
    ports = [ "9000" ]
  }
}

resource "google_compute_firewall" "fw_app_db" {
  name = var.fw_app_db_name
  network = var.vpc_id
  description = "Allow communication from App to MySQL Database"
  direction = "EGRESS"

  target_service_accounts = [
    google_service_account.sa_app.email
  ]

  destination_ranges = [ "10.0.3.0/24" ]

  allow {
    protocol = "tcp"
    ports = [ "3306" ]
  }
}

resource "google_secret_manager_secret" "sm_db" {
  secret_id = var.sm_db_name

  replication {
    auto {}
  }
}

resource "random_password" "db_pwd" {
  length = 32
  special = true
  override_special = "!@#$*%-_+"
}

resource "google_secret_manager_secret_version" "sm_version" {
  secret = google_secret_manager_secret.sm_db.id
  secret_data = random_password.db_pwd.result
}