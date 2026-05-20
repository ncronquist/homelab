# -----------------------------------------------------------------------------
# DNS Records — Local Service Subdomains
# -----------------------------------------------------------------------------
#
# All homelab subdomains resolve to the MacBook's static LAN IP (192.168.4.31).
# Caddy, running inside OrbStack, handles TLS termination and reverse-proxies
# each request to the correct container based on the Host header.
#
# This eliminates the AdGuard DNS chicken-and-egg problem: the UDM handles
# DNS natively. If Docker goes down, DNS still works for the rest of the house.
#
# To bootstrap (first run):
#   terrifi verify-connection
#   terraform init
#   terraform plan
#   terraform apply
#
# To import existing records if any were created manually:
#   terrifi generate-imports terrifi_dns_record > imports/dns_imports.tf
# -----------------------------------------------------------------------------

locals {
  # All service subdomains that should resolve to the MacBook's LAN IP.
  # These map to Caddy virtual-host blocks in apps/caddy/Caddyfile.
  service_subdomains = toset([
    # Media
    "jellyfin",
    "transmission",
    "radarr",
    "sonarr",
    "prowlarr",
    "jellyseerr",
    # DNS & Networking
    "adguard",
    # Monitoring
    "status",
    "beszel",
    "logs",
    # Books
    "calibre",
    "books",
    # Dev Tools
    "git",
    "coder",
  ])
}

# A-record for each service subdomain → MacBook LAN IP
resource "terrifi_dns_record" "homelab_services" {
  for_each = local.service_subdomains

  name  = "${each.key}.${var.home_domain}"
  type  = "A"
  value = var.macbook_ip
}

# -----------------------------------------------------------------------------
# Coder Wildcard — Workspace Port-Forwarding
# -----------------------------------------------------------------------------
#
# Coder uses *.coder.home.ncronquist.com for workspace-level port-forwarding
# and web terminals. This requires a wildcard DNS entry in the UDM.
#
# NOTE: If terrifi does not support wildcard names (name = "*.coder.*"),
# create this record manually in the UDM web UI:
#   Name:  *.coder.home.ncronquist.com
#   Type:  A
#   Value: 192.168.4.31
#
# Then import it:
#   terrifi generate-imports terrifi_dns_record
#
resource "terrifi_dns_record" "coder_wildcard" {
  name  = "*.coder.${var.home_domain}"
  type  = "A"
  value = var.macbook_ip
}
