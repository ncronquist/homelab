# Networking — Unifi Dream Machine Management

Terraform configuration for managing the Unifi Dream Machine (UDM) router using the [terraform-provider-terrifi](https://github.com/alexklibisz/terraform-provider-terrifi).

## Overview

This project manages the UDM router configuration as infrastructure-as-code, including:

- **Networks** — VLANs and subnet configuration
- **WLANs** — Wi-Fi network definitions
- **Firewall** — Zones and policies
- **DNS Records** — Router-level DNS entries
- **Client Devices** — Known device management

## Prerequisites

- [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) >= 1.5
- UDM API key (Settings → Admins → Create API Key)
- Network access to the UDM controller

## Bootstrap Workflow

The terrifi provider includes a CLI that can generate Terraform import blocks from your live UDM configuration:

```bash
# 1. Set environment variables
export UNIFI_API="https://192.168.1.1"
export UNIFI_API_KEY="your-api-key"
export UNIFI_INSECURE="true"

# 2. Verify connectivity
terrifi verify-connection

# 3. Generate import blocks for each resource type
terrifi generate-imports terrifi_network
terrifi generate-imports terrifi_wlan
terrifi generate-imports terrifi_firewall_zone
terrifi generate-imports terrifi_firewall_policy
terrifi generate-imports terrifi_dns_record
terrifi generate-imports terrifi_client_device

# 4. Copy generated blocks into the appropriate .tf files

# 5. Initialize and verify
terraform init
terraform plan
terraform apply
```

## Usage

```bash
# Copy environment template
cp .env.example .env
# Edit .env with your UDM credentials

# Source environment variables
source .env

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes (CAUTION: can disrupt network connectivity)
terraform apply
```

## Files

| File | Purpose |
|---|---|
| `providers.tf` | Terrifi provider configuration |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Output value definitions |
| `networks.tf` | Network/VLAN resources |
| `firewall.tf` | Firewall zones and policies |
| `dns.tf` | DNS record resources |
| `wlans.tf` | Wireless network resources |
| `clients.tf` | Client device resources |

See [SPEC.md](./SPEC.md) for detailed specifications.
