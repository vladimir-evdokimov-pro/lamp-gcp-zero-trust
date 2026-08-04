# VMs Compute Engine (Web & App) + OS Login

resource "google_compute_instance" "web_vm" {
  name = var.web_vm_name
  machine_type = var.machine_type
  project = var.project_id
  zone = var.zone

  boot_disk {
    initialize_params {
      image = var.image_boot
    }
  }

  network_interface {
    subnetwork = var.sb_web_id
  }
  service_account {
    email = var.sa_web_email
    scopes = [ "cloud-platform" ]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot = true
    enable_vtpm = true
  }
}

resource "google_compute_instance" "app_vm" {
  name = var.app_vm_name
  machine_type = var.machine_type
  project = var.project_id
  zone = var.zone

  boot_disk {
    initialize_params {
      image = var.image_boot
    }
  }

  network_interface {
    subnetwork = var.sb_app_id
  }

  service_account {
    email = var.sa_app_email
    scopes = [ "cloud-platform" ]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot = true
    enable_vtpm = true
  }
}