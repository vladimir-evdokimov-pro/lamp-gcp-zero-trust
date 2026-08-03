# Infrastructure Setup and Deployment Guide

This document provides step-by-step instructions for bootstrapping, provisioning, and configuring the Zero-Trust 3-Tier LAMP architecture on Google Cloud Platform (GCP).

---

## 1. Prerequisites

Ensure the following tools are installed on your local workstation:

* **gcloud CLI** >= 450.0.0
* **Terraform** >= 1.5.0
* **Ansible** >= 2.15.0
* **Git** >= 2.40.0

### GCP Authentication
Authenticate with Google Cloud and configure default application credentials:

```bash
gcloud auth login
gcloud auth application-default login
```

---

## 2. Phase 1: Environment Bootstrap (GCP CLI)

Execute these baseline setup steps using the Google Cloud CLI before running Terraform.

### A. Project Creation and Billing Link
```bash
# Set environment variables
export PROJECT_ID="lamp-3tier-production"
export BILLING_ACCOUNT_ID="YOUR_BILLING_ACCOUNT_ID" # Replace with your Billing Account ID

# Create GCP Project
gcloud projects create ${PROJECT_ID} --set-as-default

# Link Billing Account
gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID}
```

### B. Enable Baseline Management APIs
Enable the essential APIs required by Terraform to manage service usage and resource hierarchy:

```bash
gcloud services enable \
    serviceusage.googleapis.com \
    cloudresourcemanager.googleapis.com
```

### C. Create GCS Bucket for Terraform Remote State
Provision a secure, versioned Google Cloud Storage bucket to store `terraform.tfstate`:

```bash
export BUCKET_NAME="${PROJECT_ID}-tfstate"

gcloud storage buckets create gs://${BUCKET_NAME} \
    --project=${PROJECT_ID} \
    --location=EUROPE-WEST9 \
    --uniform-bucket-level-access

gcloud storage buckets update gs://${BUCKET_NAME} --versioning
```

---

## 3. Phase 1: Core Infrastructure Provisioning (Terraform)

Once the bootstrap process is complete, Terraform manages all remaining APIs, IAM accounts, and infrastructure components declaratively.

### A. Remote Backend Configuration
Verify that `terraform/main.tf` points to your backend bucket:

```hcl
terraform {
  backend "gcs" {
    bucket = "lamp-3tier-production-tfstate"
    prefix = "terraform/state"
  }
}
```

### B. Terraform Execution Workflow
```bash
cd terraform/

# Initialize modules and backend
terraform init

# Review planned changes
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan
```

---

## 4. Security and Secrets Setup

Inject initial credentials into GCP Secret Manager:

```bash
# Generate a strong database password
DB_PASS=$(openssl rand -base64 24)

# Add secret version to GCP Secret Manager
echo -n "$DB_PASS" | gcloud secrets versions add cloud-sql-db-password --data-file=- --project=${PROJECT_ID}
```

---

## 5. Configuration Management (Ansible via IAP)

Target Compute VMs lack public IP addresses. Access and management are proxied using Google Identity-Aware Proxy (IAP) tunnels.

### A. Local SSH Proxy Configuration
Add the following configuration to `~/.ssh/config`:

```text
Host 10.0.1.*
    ProxyCommand gcloud compute start-iap-tunnel %h %p --listen-on-stdin --zone=europe-west9-a
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### B. Execute Ansible Playbooks
```bash
cd ../ansible/

# Verify IAP connectivity against dynamic inventory
ansible all -m ping -i inventory/gcp_dynamic_inventory.yml

# Run playbook execution
ansible-playbook -i inventory/gcp_dynamic_inventory.yml site.yml
```

---

## 6. Verification and Acceptance

Validate the deployment:

1. **HTTP Ingress Check:**
   ```bash
   curl -I http://<LOAD_BALANCER_IP>
   ```

2. **IAP SSH Connectivity:**
   ```bash
   gcloud compute ssh --zone=europe-west9-a vm-web-prod --tunnel-through-iap
   ```

3. **Cloud SQL Private Service Connect Resolution:**
   ```bash
   nc -zv 10.0.1.50 3306
   ```

---

## 7. Environment Teardown

To destroy all provisioned infrastructure and avoid unnecessary costs:

```bash
cd terraform/
terraform destroy
```