# Enterprise Zero-Trust 3-Tier LAMP Architecture on GCP

[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Security](https://img.shields.io/badge/Security-Zero_Trust-00C853?style=for-the-badge)](#security--zero-trust-posture)

> **Modernizing Legacy Architectures:** A production-grade, fully automated migration from a classic single-server LAMP stack to a Zero-Trust, highly secure 3-Tier infrastructure on Google Cloud Platform using Infrastructure as Code (IaC) and GitOps principles.

---

## Executive Summary

This repository demonstrates how to transition a traditional web application into a cloud-native, enterprise-grade environment. The architecture enforces strict network isolation, keyless access mechanisms, centralized secret handling, and dynamic CI/CD configuration management.

---

## Security & Zero-Trust Posture

* **100% Private Network (No Public IPs):** Web and Application Compute instances operate inside a strictly isolated VPC subnet with zero public IP addresses attached.
* **Identity-Aware Proxy (IAP) & OS Login:** Bastionless administration. SSH access is granted dynamic access through Google IAP tunnels authenticated via IAM roles.
* **Private Service Connect (PSC):** Cloud SQL database connectivity is exposed internally via a dedicated local PSC Endpoint (no VPC Peering or public IP exposure).
* **Workload Identity Federation (WIF):** Short-lived OIDC tokens for GitHub Actions runners, eliminating long-lived GCP service account keys.
* **Centralized Secret Management:** Database credentials and runtime configs are dynamically retrieved at boot via GCP Secret Manager.

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

            subgraph SUBNET["<font color='#166534'><b>Private Subnet (10.0.1.0/24)</b></font>"]
                VM_Web["Web VM (10.0.1.10)<br/>- Apache / FastCGI Proxy<br/>- Label: tier=web"]
                VM_App["App VM (10.0.1.20)<br/>- PHP-FPM / phpMyAdmin<br/>- Label: tier=app"]
                PSC_Endpoint["PSC Endpoint (10.0.1.50)<br/>- Local Cloud SQL Interface"]
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
    VM_App -.->|3. Retrieve DB Password| Secrets

    class User,GitHub external;
    class LB,NAT,IAP gcpBlue;
    class VM_Web,VM_App,PSC_Endpoint gcpGreen;
    class WIF,Secrets gcpRed;
    class CloudSQL gcpYellow;
```

---

## Repository Structure

```text
lamp-gcp-zero-trust/
├── .github/
│   └── workflows/          # GitHub Actions CI/CD (Terraform & Ansible Validation)
├── terraform/              # Infrastructure as Code (Modular Design)
│   ├── modules/            # Reusable modules (VPC, Compute, CloudSQL, IAP, IAM)
│   ├── main.tf             # Core provider configuration and remote state setup
│   ├── outputs.tf          # Provisioned infrastructure outputs
│   └── variables.tf        # Environment input variables
├── ansible/                # Configuration Management & Hardening
│   ├── inventory/          # Dynamic GCP Compute Inventory definitions
│   └── roles/              # Ansible roles (Apache, PHP-FPM, Security Hardening)
└── docs/                   # Detailed Project Documentation & Runbooks
    └── setup_guide.md      # Step-by-step infrastructure provisioning guide
```

---

## Implementation Roadmap

- [x] **Phase 1: Architecture & Network Topology Definition** (VPC, Subnetting, Security Boundaries)
- [x] **Phase 2: Repository Governance** (Branch Protection, GitOps Workflows)
- [x] **Phase 3: Core Infrastructure Provisioning (Terraform)**
  - [X] Custom VPC, Subnets, Cloud NAT & Router
  - [X] Private Compute Instances (Web & App Tiers)
  - [X] Cloud SQL (MySQL) with Private Service Connect (PSC)
- [X] **Phase 4: Security & IAM Hardening**
  - [X] Workload Identity Federation setup
  - [X] Secret Manager integration
  - [X] IAP SSH Tunneling configuration
- [ ] **Phase 5: Automated Configuration (Ansible)**
  - [ ] Web/App runtime setup (Apache, PHP-FPM)
  - [ ] OS Security hardening & dynamic inventory integration
- [ ] **Phase 6: Continuous Integration & Validation**

---

## Getting Started

To replicate or deploy this infrastructure, refer to the step-by-step setup documentation:
[Read the Setup Guide (docs/setup_guide.md)](docs/setup_guide.md)

---

## Author

* **Vladimir Evdokimov** - Cloud & DevOps Infrastructure Project  
* **GitHub:** [@vladimir-evdokimov-pro](https://github.com/vladimir-evdokimov-pro)