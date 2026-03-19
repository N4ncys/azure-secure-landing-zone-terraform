# Azure Secure Landing Zone (Terraform)

## Overview
This project demonstrates the design and implementation of an enterprise-grade Azure landing zone using Terraform. The architecture follows best practices for governance, security, and scalability.

## Architecture
- Hub-spoke network topology
- Centralized security with Azure Firewall
- Private endpoints for Storage and Key Vault
- No public access to workloads
- Bastion-based secure VM access

## Key Components

### Networking
- Virtual Network: vnet-prod-spoke (10.1.0.0/16)
- Subnets:
  - snet-app (10.1.1.0/24)
  - snet-private-endpoints (10.1.2.0/24)
- Route Table: rt-prod-app (forced tunneling via firewall)
- Network Security Group: nsg-prod-app

### Security
- Azure Bastion for secure access
- Private Endpoints:
  - Storage (blob)
  - Key Vault
- Public network access disabled

### Monitoring
- Log Analytics Workspace (law-platform)
- Microsoft Defender for Cloud enabled

### Governance
- Azure Policies:
  - Block public IPs
  - Require environment tagging
- RBAC:
  - Dev-Team assigned Contributor role on production subscription

## Terraform Structure


## Outcomes
- Infrastructure fully managed using Terraform (Infrastructure as Code)
- Zero configuration drift between Azure and Terraform state
- Secure, private-only architecture with no public exposure
- Enforced governance using Azure Policy and RBAC
- Production-ready cloud foundation aligned with enterprise best practices

## Future Improvements
- Extend Terraform to include Azure Firewall and Bastion
- Implement remote backend using Azure Storage for state management
- Refactor into reusable Terraform modules
- Add CI/CD pipeline for automated deployments

