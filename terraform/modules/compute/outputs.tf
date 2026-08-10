output "web_vm_ip" {
  description = "Return IP address of Web instance"
  value = google_compute_instance.web_vm.network_interface.0.network_ip
}

output "app_vm_ip" {
  description = "Return IP address of App instance"
  value = google_compute_instance.app_vm.network_interface.0.network_ip
}