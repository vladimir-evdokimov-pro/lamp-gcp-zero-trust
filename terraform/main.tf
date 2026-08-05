resource "google_project_service" "apis" {
  for_each = var.gcp_apis

  project = var.project_id
  service = each.key
  disable_on_destroy = false
}
module "network" {
  source = "./modules/network"
  project_id = var.project_id
  region = var.region
}
module "security" {
  source = "./modules/security"
  project_id = var.project_id
  vpc_id = module.network.vpc_id
}
module "compute" {
  source = "./modules/compute"
  project_id = var.project_id
  network = module.network.vpc_id
  region = var.region
  zone = var.zone
  sb_web_id = module.network.sb_web_id
  sb_app_id = module.network.sb_app_id
  sa_web_email = module.security.sa_web_email
  sa_app_email = module.security.sa_app_email

  depends_on = [ google_project_service.apis ]
}
module "database" {
  source = "./modules/database"
  project_id = var.project_id
  region = var.region
  vpc_id = module.network.vpc_id
  subnet_id = module.network.sb_data_id
  db_password = module.security.db_password
}