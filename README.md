# Enterprise Zero-Trust 3-Tier LAMP Architecture on GCP

[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Security](https://img.shields.io/badge/Security-Zero_Trust-00C853?style=for-the-badge)](#security--zero-trust-posture)

> **Modernizing Legacy Architectures:** A production-grade, fully automated migration from a classic single-server LAMP stack to a Zero-Trust, highly secure 3-Tier infrastructure on Google Cloud Platform using Infrastructure as Code (IaC) and GitOps principles.

---

## Executive Summary

This repository demonstrates how to transition a traditional web application into a cloud-native, enterprise-grade environment. The architecture enforces strict network isolation, keyless access mechanisms, centralized secret handling, and dynamic configuration management.

---

## Security & Zero-Trust Posture

* **100% Private Network (No Public IPs on Internal Compute):** Application and Database tiers operate inside isolated VPC subnets without public IP addresses attached.
* **Identity-Aware Proxy (IAP) & OS Login:** Bastionless administration. SSH access is granted via dynamic Google IAP tunnels authenticated through IAM roles.
* **Private Service Connect (PSC):** Cloud SQL database connectivity is exposed internally via a dedicated local PSC Endpoint (no VPC Peering or public IP exposure).
* **Workload Identity Federation (WIF):** Short-lived OIDC tokens for GitHub Actions runners, eliminating long-lived GCP service account keys.
* **Centralized Secret Management:** Database credentials and runtime keys are dynamically retrieved via GCP Secret Manager.
* **Tiered Decoupling:** Apache serves static assets on the Web Tier and proxies FastCGI requests (`:9000`) to PHP-FPM running on an isolated App Tier.

---

## Architecture Diagram

```mermaid
%%{
  init: {
    'theme': 'base',
    'themeVariables': {
      'primaryColor': '#ffffff',
      'primaryTextColor': '#0f172a',
      'primaryBorderColor': '#475569',
      'lineColor': '#475569',
      'textColor': '#0f172a',
      'edgeLabelBackground': '#ffffff',
      'tertiaryColor': '#f8fafc'
    }
  }
}%%
graph TD
    style EXTERNAL fill:#f8fafc,stroke:#64748b,stroke-width:2px,stroke-dasharray: 5 5
    style GCP_PROJECT fill:#f1f5f9,stroke:#334155,stroke-width:2px
    style SECURITY_LAYER fill:#fef2f2,stroke:#ef4444,stroke-width:2px
    style VPC fill:#eff6ff,stroke:#3b82f6,stroke-width:2px
    style SUBNET fill:#f0fdf4,stroke:#22c55e,stroke-width:2px
    style GCP_MANAGED fill:#fefce8,stroke:#eab308,stroke-width:2px

    classDef external fill:#ffffff,stroke:#475569,stroke-width:2px,color:#0f172a;
    classDef gcpBlue fill:#ffffff,stroke:#2563eb,stroke-width:2px,color:#1e3a8a;
    classDef gcpGreen fill:#ffffff,stroke:#16a34a,stroke-width:2px,color:#14532d;
    classDef gcpYellow fill:#ffffff,stroke:#ca8a04,stroke-width:2px,color:#713f12;
    classDef gcpRed fill:#ffffff,stroke:#dc2626,stroke-width:2px,color:#7f1d1d;

    subgraph EXTERNAL["<font color='#334155'><b>External Layer</b></font>"]
        User["Web Client"]
        GitHub["CI/CD Pipeline<br/>(GitHub Actions)"]
    end

    subgraph GCP_PROJECT["<font color='#0f172a'><b>GCP Project: lamp-3tier-production</b></font>"]

        subgraph SECURITY_LAYER["<font color='#991b1b'><b>IAM & Centralized Security</b></font>"]
            WIF["Workload Identity Federation<br/>(Short-Lived OIDC Auth)"]
            Secrets["GCP Secret Manager<br/>(Database Credentials)"]
        end

        LB["External HTTP(S) Load Balancer<br/>(Single Public Ingress Point)"]

        subgraph VPC["<font color='#1e40af'><b>Custom VPC Network (100% Private)</b></font>"]

            subgraph SUBNET["<font color='#166534'><b>Private Subnets</b></font>"]
                VM_Web["Web VM: web-server1 (10.0.1.2)<br/>- Apache / Static Assets<br/>- Reverse Proxy FastCGI"]
                VM_App["App VM: app-server1 (10.0.2.2)<br/>- PHP-FPM / phpMyAdmin Core<br/>- No Public IP"]
                PSC_Endpoint["PSC Endpoint (10.0.3.2)<br/>- Local Cloud SQL Interface"]
            end

            NAT["Cloud Router + Cloud NAT<br/>(Outbound Egress for apt)"]
            IAP["Identity-Aware Proxy (IAP)<br/>(SSH Tunneling w/o Public IP)"]
        end

        subgraph GCP_MANAGED["<font color='#854d0e'><b>Google Managed Services</b></font>"]
            CloudSQL[("Cloud SQL Instance<br/>- MySQL 8.0<br/>- Private via PSC Attachment")]
        end
    end

    User -->|HTTP :80 / HTTPS :443| LB
    LB -->|Forwarding Ingress| VM_Web
    VM_Web -->|FCGI :9000| VM_App
    VM_App -->|MySQL :3306| PSC_Endpoint
    PSC_Endpoint ==>|Private PSC Tunnel| CloudSQL

    VM_Web -.->|Egress apt-get| NAT
    VM_App -.->|Egress apt-get| NAT

    GitHub -->|1. OIDC Token Request| WIF
    GitHub ==>|2. Ansible via IAP Tunnel :22| IAP
    IAP ==>|OS Login / Private SSH| VM_Web
    IAP ==>|OS Login / Private SSH| VM_App
    VM_App -.->|3. Retrieve Secrets| Secrets

    class User,GitHub external;
    class LB,NAT,IAP gcpBlue;
    class VM_Web,VM_App,PSC_Endpoint gcpGreen;
    class WIF,Secrets gcpRed;
    class CloudSQL gcpYellow;
```

---

## Repository Structure

```text
.
├── README.md
├── ansible/
│   ├── ansible.cfg              # Ansible global configuration
│   ├── inventory.gcp.yml        # GCP Compute dynamic inventory configuration
│   ├── group_vars/
│   │   ├── all.yml.example      # Example environment variables template
│   │   ├── role_app.yml         # Application tier variables
│   │   └── role_web.yml         # Web tier variables
│   ├── playbooks/
│   │   ├── application.yml      # PHP-FPM and phpMyAdmin backend deployment
│   │   └── webserver.yml        # Apache HTTP Server & static assets setup
│   └── templates/
│       ├── apache_vhost.conf.j2 # VirtualHost configuration with FastCGI proxy
│       ├── php_fpm_pool.conf.j2 # PHP-FPM pool configuration
│       └── pma_config.inc.php.j2# phpMyAdmin configuration template
├── docs/
│   ├── architecture_diagram.png # Architecture visual diagram
│   └── setup_guide.md           # Step-by-step installation guide
└── terraform/
    ├── ansible.tf               # Integration helpers for Ansible inventory
    ├── main.tf                  # Infrastructure module invocations
    ├── outputs.tf               # Infrastructure deployment outputs
    ├── providers.tf             # Terraform provider definitions
    ├── terraform.tfvars.example # Input variables example template
    ├── variables.tf             # Core variable definitions
    └── modules/
        ├── compute/             # Virtual machine instances setup
        ├── database/            # Cloud SQL MySQL and PSC provisioning
        ├── load-balancer/       # GCP External HTTP Load Balancer setup
        ├── network/             # VPC, subnets, NAT, and firewall rules
        └── security/            # IAM, Service Accounts, Secret Manager & IAP
```

---

## Implementation Roadmap

- [x] **Phase 1: Architecture & Network Topology Definition** (VPC, Subnetting, Security Boundaries)
- [x] **Phase 2: Repository Governance** (Branch Protection, GitOps Workflows)
- [x] **Phase 3: Core Infrastructure Provisioning (Terraform)**
  - [x] Custom VPC, Subnets, Cloud NAT & Router
  - [x] Private Compute Instances (Web & App Tiers)
  - [x] Cloud SQL (MySQL) with Private Service Connect (PSC)
- [x] **Phase 4: Security & IAM Hardening**
  - [x] Workload Identity Federation setup
  - [x] Secret Manager integration
  - [x] IAP SSH Tunneling configuration
- [x] **Phase 5: Automated Configuration (Ansible)**
  - [x] Web tier setup (Apache, FastCGI Proxy, Static Assets)
  - [x] App tier setup (PHP-FPM, phpMyAdmin Core execution)
  - [x] Dynamic inventory integration
- [ ] **Phase 6: Continuous Integration & Validation**

---

## Deployment Quickstart

### Prerequisites

* **Google Cloud SDK (`gcloud`)** installed and authenticated.
* **Terraform** `>= 1.5.0`
* **Ansible** `>= 2.15.0` with the `google.cloud` collection.
* Local SSH keypair generated at `ansible/id_ssh`.

### 1. Provision Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Update terraform.tfvars with your GCP project details
terraform init
terraform apply
```

### 2. Configure Software Stack

```bash
cd ../ansible
cp group_vars/all.yml.example group_vars/all.yml
# Update variables in group_vars/all.yml if necessary

# Deploy Web Tier (Apache Reverse Proxy & Static Assets)
ansible-playbook -i inventory.gcp.yml playbooks/webserver.yml

# Deploy Application Tier (PHP-FPM & phpMyAdmin Backend)
ansible-playbook -i inventory.gcp.yml playbooks/application.yml
```

---

## Getting Started

To replicate or deploy this infrastructure in detail, refer to the step-by-step setup documentation:  
[Read the Setup Guide (docs/setup_guide.md)](docs/setup_guide.md)

---

## Author

* **Vladimir Evdokimov** - Cloud & DevOps Infrastructure Project  
* **GitHub:** [@vladimir-evdokimov-pro](https://github.com/vladimir-evdokimov-pro)