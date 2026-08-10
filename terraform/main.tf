resource "google_project_service" "apis" {
  for_each = var.gcp_apis

  project = var.project_id
  service = each.key
  disable_on_destroy = false
}

