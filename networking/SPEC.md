# Networking Project — Specification

## Provider Overview

The [terraform-provider-terrifi](https://github.com/alexklibisz/terraform-provider-terrifi) is a Terraform/OpenTofu provider for managing Ubiquiti UniFi network infrastructure. It interacts with the UniFi OS Controller's HTTP API.

**Registry:** https://search.opentofu.org/provider/alexklibisz/terrifi/latest

### Supported Resources

| Resource Type | Description |
|---|---|
| `terrifi_network` | VLANs, subnets, network configuration |
| `terrifi_wlan` | Wireless LAN (Wi-Fi) networks |
| `terrifi_firewall_zone` | Firewall zone groupings |
| `terrifi_firewall_policy` | Firewall rules and policies |
| `terrifi_dns_record` | DNS record management |
| `terrifi_client_device` | Client device identification |

---

## Authentication

**Recommended: API Key authentication**

1. In the UDM web UI: Settings → Admins & Users
2. Create a dedicated admin user for Terraform (limited admin role recommended)
3. Generate an API key for that user
4. Set the `UNIFI_API_KEY` environment variable

Environment variables:

| Variable | Required | Description |
|---|---|---|
| `UNIFI_API` | Yes | UDM controller URL (e.g., `https://192.168.1.1`) |
| `UNIFI_API_KEY` | Yes | API key for authentication |
| `UNIFI_INSECURE` | Yes | Set to `true` (UDM uses self-signed certs) |
| `UNIFI_SITE` | No | Site name (defaults to `default`) |

---

## Import Workflow

The terrifi CLI generates Terraform import blocks and resource stubs from live infrastructure.

### Step-by-Step

```bash
# 1. Install the terrifi CLI (comes with the provider)
# See: https://github.com/alexklibisz/terraform-provider-terrifi/releases

# 2. Set environment variables
export UNIFI_API="https://192.168.1.1"
export UNIFI_API_KEY="your-api-key"
export UNIFI_INSECURE="true"

# 3. Verify connection
terrifi verify-connection

# 4. Generate imports for each resource type
terrifi generate-imports terrifi_network > imports/networks.tf
terrifi generate-imports terrifi_wlan > imports/wlans.tf
terrifi generate-imports terrifi_firewall_zone > imports/firewall_zones.tf
terrifi generate-imports terrifi_firewall_policy > imports/firewall_policies.tf
terrifi generate-imports terrifi_dns_record > imports/dns.tf
terrifi generate-imports terrifi_client_device > imports/clients.tf

# 5. Review generated files and merge into project .tf files

# 6. Run terraform plan to verify
terraform plan

# 7. Apply to import existing state
terraform apply
```

### Post-Import Checklist

- [ ] All networks imported and match live configuration
- [ ] All WLANs imported
- [ ] Firewall zones and policies imported
- [ ] DNS records imported
- [ ] `terraform plan` shows no changes (clean state)

---

## Configuration Goals

### Primary

1. **Import existing infrastructure** — All current networks, WLANs, firewall rules, and DNS records managed via Terraform
2. **DNS A-records for all service subdomains** — The UDM resolves `*.home.ncronquist.com` natively to the MacBook's static LAN IP (`192.168.4.31`). Caddy handles TLS and routing. No Docker dependency in the DNS path.
3. **Documentation** — All managed resources documented in code with comments

### Key Configuration: DNS Records

All homelab service subdomains are configured as A-records in `dns.tf` pointing to the MacBook's LAN IP. This means:
- If OrbStack or Docker crashes, the rest of the house still has internet (UDM DNS is unaffected)
- If the Mac itself goes down, the services are unavailable but DNS resolution to the WAN still works via the UDM's upstream resolvers
- No `dhcp_dns` override is required — the UDM uses its own DNS engine for local records

```hcl
# Example: After importing, the default network should NOT have dhcp_dns
# pointing to AdGuard or any Docker container.
# resource "terrifi_network" "default" {
#   name         = "Default"
#   purpose      = "corporate"
#   dhcp_enabled = true
#   # Use UDM's own upstream DNS resolvers (Cloudflare by default)
#   # dhcp_dns = ["1.1.1.1", "1.0.0.1"]   # Optional: explicit upstream
# }
```

### AdGuard Home Role (Changed)

AdGuard Home still runs in Docker but is **no longer in the DNS critical path**:
- It is accessible at `adguard.home.ncronquist.com` via Caddy
- It can be used as a **Tailscale Split DNS resolver** — see `docs/runbooks/tailscale-split-dns.md`
- It does NOT have port 53 exposed to the host
- It does NOT act as the DHCP DNS server for the network

### Future Enhancements

- [ ] Define VLANs for network segmentation:
  - **Trusted** — Personal devices, full access
  - **IoT** — Smart home devices, restricted internet access
  - **Guest** — Visitor Wi-Fi, internet-only
- [ ] Firewall policies between VLANs
- [ ] Static routes for Tailscale subnet routing

---

## Limitations & Gotchas

> **⚠️ Important:** This provider is a hobby project (v0.2.x). Exercise caution.

1. **Pin the provider version** — Always use `version = "~> 0.2"` to avoid breaking changes
2. **Self-signed certs** — UDM uses self-signed certificates; `allow_insecure = true` is required
3. **API instability** — The UniFi API can change with firmware updates; monitor for drift
4. **Network disruption risk** — Incorrect Terraform applies can break network connectivity. Always review `terraform plan` carefully
5. **State drift** — Users have reported "unexpected new value" errors where attributes change unexpectedly
6. **Test in stages** — Import and modify one resource type at a time

---

## File Layout

```
networking/
├── README.md               # Project overview
├── SPEC.md                 # This file
├── providers.tf            # Provider configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── networks.tf             # Network/VLAN resources
├── firewall.tf             # Firewall zones and policies
├── dns.tf                  # DNS records
├── wlans.tf                # Wi-Fi networks
├── clients.tf              # Client devices
├── terraform.tfvars.example # Example variable values
└── .env.example            # Environment variable template
```
