# Infrastructure Setup and Deployment Guide

This document provides step-by-step instructions for bootstrapping, provisioning, and configuring the Zero-Trust 3-Tier LAMP architecture on Google Cloud Platform (GCP).

---

## 1. Prerequisites

Ensure the following tools are installed on your workstation or execution environment:

* **gcloud CLI** >= 450.0.0
* **Terraform** >= 1.5.0
* **Ansible** >= 2.15.0 with `google.cloud` collection
* **Git** >= 2.40.0

### GCP Authentication
Authenticate with Google Cloud and configure default application credentials:

```bash
gcloud auth login
gcloud auth application-default login
```

---

## 2. Phase 1: Environment Bootstrap & Security Setup (GCP CLI)

Execute these baseline setup steps using the Google Cloud CLI before running Terraform or CI/CD pipelines.

### A. Project Creation and Billing Link
```bash
export PROJECT_ID="<YOUR_PROJECT_ID>"              # e.g., my-lamp-production
export BILLING_ACCOUNT_ID="<YOUR_BILLING_ACCOUNT_ID>" # Replace with your GCP Billing Account ID

# Create GCP Project
gcloud projects create ${PROJECT_ID} --set-as-default

# Link Billing Account
gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID}
```

> **Note on GCP APIs:** All required service APIs (Compute, IAP, Secret Manager, Cloud SQL, etc.) are declared and automatically enabled via Terraform modules (`google_project_service`).

### B. Create GCS Bucket for Terraform Remote State
Provision a secure, versioned Google Cloud Storage bucket to store `terraform.tfstate`:

```bash
export BUCKET_NAME="${PROJECT_ID}-tfstate"
export REGION="<YOUR_GCP_REGION>" # e.g., europe-west9

gcloud storage buckets create gs://${BUCKET_NAME} \
    --project=${PROJECT_ID} \
    --location=${REGION} \
    --uniform-bucket-level-access

gcloud storage buckets update gs://${BUCKET_NAME} --versioning
```

### C. Workload Identity Federation (WIF) & IAM Setup
Configure Keyless Authentication between GitHub Actions and GCP using dedicated Service Accounts and OIDC.

```bash
export GITHUB_REPO="<YOUR_GITHUB_ORG_OR_USER>/<YOUR_GITHUB_REPO>" # e.g., my-org/lamp-gcp-zero-trust
export SA_NAME="gh-actions-deployer"
export POOL_NAME="github-wif-pool"
export PROVIDER_NAME="github-wif-provider"

# 1. Create dedicated Service Account for CI/CD
gcloud iam service-accounts create ${SA_NAME} \
    --display-name="GitHub Actions Deployer Service Account"

# 2. Grant Required IAM Roles
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iap.tunnelResourceAccessor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# 3. Create Workload Identity Pool
gcloud iam workload-identity-pools create ${POOL_NAME} \
    --location="global" \
    --display-name="GitHub Actions Pool"

# 4. Create Workload Identity Provider for GitHub OIDC
gcloud iam workload-identity-pools providers create-oidc ${PROVIDER_NAME} \
    --location="global" \
    --workload-identity-pool=${POOL_NAME} \
    --display-name="GitHub Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --issuer-uri="[https://token.actions.githubusercontent.com](https://token.actions.githubusercontent.com)"

# 5. Bind Service Account to GitHub Repository
export WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe ${POOL_NAME} --location="global" --format="value(name)")

gcloud iam service-accounts add-iam-policy-binding ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://[iam.googleapis.com/$](https://iam.googleapis.com/$){WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${GITHUB_REPO}"
```

---

## 3. GitHub Actions Environment Configuration

Before triggering CI/CD pipelines, configure the following **Repository Variables** in GitHub (`Settings -> Secrets and variables -> Actions -> Variables`):

| Variable Name | Description | Placeholder / Example Value |
| :--- | :--- | :--- |
| `GCP_PROJECT_ID` | Google Cloud Project Identifier | `<YOUR_PROJECT_ID>` |
| `GCP_REGION` | Target GCP deployment region | `<YOUR_GCP_REGION>` *(e.g., `europe-west9`)* |
| `GCP_ZONE` | Target GCP availability zone | `<YOUR_GCP_ZONE>` *(e.g., `europe-west9-a`)* |
| `GCP_SERVICE_ACCOUNT` | Email of the CI/CD Service Account | `gh-actions-deployer@<YOUR_PROJECT_ID>.iam.gserviceaccount.com` |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full GCP path to the WIF Provider | `projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_NAME>/providers/<PROVIDER_NAME>` |
| `GCP_VM_USERNAME` | SSH username for Ansible OS Login | `admin` |

---

## 4. Phase 2: Core Infrastructure Provisioning (Terraform)

### A. Remote Backend Configuration
Verify `terraform/main.tf` points to your state bucket:

```hcl
terraform {
  backend "gcs" {
    bucket = "<YOUR_PROJECT_ID>-tfstate"
    prefix = "terraform/state"
  }
}
```

### B. Execution Workflow
```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars # Edit variables with your specific values

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## 5. Phase 3: Secrets Management

Inject database credentials into GCP Secret Manager:

```bash
DB_PASS=$(openssl rand -base64 24)

echo -n "$DB_PASS" | gcloud secrets versions add cloud-sql-db-password \
    --data-file=- \
    --project=${PROJECT_ID}
```

---

## 6. Phase 4: Configuration Management (Ansible via IAP)

Compute instances operate inside private subnets without public IPs. All management traffic passes through Google Identity-Aware Proxy (IAP) tunnels over SSH.

### A. IAP Dynamic Inventory Configuration (`ansible/inventory.gcp.yml`)
Ensure your GCP inventory plugin file uses `auth_kind: application` and dynamic groups mapping:

```yaml
plugin: google.cloud.gcp_compute
projects:
  - "<YOUR_PROJECT_ID>"
auth_kind: application

groups:
  role_web: "'web' in name"
  role_app: "'app' in name"

keyed_groups:
  - key: labels.role
    prefix: role

hostnames:
  - name

compose:
  ansible_host: name
```

### B. Local SSH Proxy Setup (`ansible/ansible.cfg`)
Configure Ansible to proxy SSH connections through IAP automatically:

```ini
[defaults]
inventory = inventory.gcp.yml
host_key_checking = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o ProxyCommand="gcloud compute start-iap-tunnel %h %p --listen-on-stdin --zone=<YOUR_GCP_ZONE>"
```

### C. Execution
```bash
cd ansible/

# Deploy Application Tier (PHP-FPM & phpMyAdmin Core)
ansible-playbook -i inventory.gcp.yml playbooks/application.yml --private-key id_ssh

# Deploy Web Tier (Apache HTTP Server & FastCGI Proxy)
ansible-playbook -i inventory.gcp.yml playbooks/webserver.yml --private-key id_ssh
```

---

## 7. Phase 5: Verification & Acceptance

1. **HTTP Ingress Check:**
   ```bash
   curl -I http://<LOAD_BALANCER_IP>
   ```
2. **IAP SSH Connectivity Test:**
   ```bash
   gcloud compute ssh web-server1 --tunnel-through-iap --zone=<YOUR_GCP_ZONE>
   ```
3. **Local Web Server Check:**
   ```bash
   curl -I http://localhost/
   ```

---

## 8. Troubleshooting & Post-Mortem Guide

| Issue / Error | Root Cause | Resolution |
| :--- | :--- | :--- |
| **`no healthy upstream`** (Load Balancer 502/503) | Apache is stopped, returning `403/404` on `/`, or GCP Health Check hasn't received `200 OK` yet. | SSH via IAP (`gcloud compute ssh web-server1 --tunnel-through-iap`), check `curl -I http://localhost/`, ensure Apache is restarted (`systemctl restart apache2`), and index file exists. |
| **Debian Default Page shown instead of PMA** | Apache started before Ansible enabled `pma.conf`. `state: started` didn't reload runtime memory. | Change task to `state: restarted` or `reloaded` in `webserver.yml` and trigger a service reload. |
| **`Invalid value "application_default" for auth_kind`** | The `google.cloud.gcp_compute` inventory plugin requires `application` (not `application_default`). | Set `auth_kind: application` in `ansible/inventory.gcp.yml`. |
| **`skipping: no hosts matched`** in Ansible | Dynamic inventory failed to map labels or groups. | Add `groups: role_web: "'web' in name"` in `inventory.gcp.yml` to match hostnames fallback. |
| **`yaml[new-line-at-end-of-file]`** (`ansible-lint` failure) | POSIX rule requiring a trailing newline character at the end of YAML files. | Add an empty line at the very end of the playbook (`webserver.yml`). |

---

## 9. Environment Teardown

To decommission all resources and avoid unnecessary billing:

```bash
cd terraform/
terraform destroy
```