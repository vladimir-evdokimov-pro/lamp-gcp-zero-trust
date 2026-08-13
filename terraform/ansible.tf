resource "random_password" "pma_secret" {
  length  = 32
  special = false
}

resource "local_file" "group_vars" {
  filename = "${path.module}/../ansible/group_vars/all.yml"

  content = <<EOF
db_host: "${module.database.db_private_ip}"
pma_blowfish_secret: "${random_password.pma_secret.result}"
ansible_user: "${var.username}"
php_fpm_port: 9000
app_server_host: "app-server1"
EOF
}

resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

resource "local_file" "ans_priv_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "${path.module}/../ansible/id_ssh"
  file_permission = "0600"
}

resource "google_compute_project_metadata_item" "default_ssh_key" {
  key   = "ssh-keys"
  value = "${var.username}:${tls_private_key.ssh_key.public_key_openssh} ${var.username}"
}

resource "google_compute_project_metadata_item" "disable_oslogin" {
  key   = "enable-oslogin"
  value = "FALSE"
}