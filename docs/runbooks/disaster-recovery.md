# Disaster Recovery — Runbook

Guide for recovering the homelab after a failure.

## What's Backed Up

| Data | Backed Up | Location |
|---|---|---|
| Service configs | ✅ Yes | `docker/apps/*/data/` via `backup.sh` |
| Docker compose files | ✅ Yes | Git repository |
| Caddyfile / Dockerfiles | ✅ Yes | Git repository |
| Terraform state | ⚠️ Manual | `networking/terraform.tfstate` |
| TLS certificates | ❌ No | Auto-renewed by Caddy |
| Media files | ❌ No | External SSD (separate backup) |
| Container images | ❌ No | Re-pulled from registries |

## Recovery Scenarios

### Scenario 1: Single Service Failure

```bash
# Restart the service
docker compose restart <service-name>

# If that doesn't work, recreate
docker compose up -d --force-recreate <service-name>

# Check logs
docker compose logs -f <service-name>
```

### Scenario 2: Full Docker Reset

```bash
cd ~/Documents/projects/homelab/docker

# Stop everything
docker compose down

# Run setup again
./scripts/setup.sh

# Start everything
docker compose up -d
```

### Scenario 3: Restore from Backup

```bash
cd ~/Documents/projects/homelab/docker

# Stop all services
docker compose down

# Extract backup
tar -xzf /path/to/homelab-config-YYYYMMDD_HHMMSS.tar.gz

# Run setup (recreates networks)
./scripts/setup.sh

# Start services
docker compose up -d
```

### Scenario 4: New Machine Setup

1. Install macOS prerequisites (OrbStack, Terraform, Tailscale)
2. Clone the repo
3. Connect external SSD
4. Restore config backup (if available)
5. Follow [Initial Setup Runbook](./initial-setup.md)
6. Reconfigure services that need it (Uptime Kuma monitors, etc.)

### Scenario 5: Terraform State Recovery

If Terraform state is lost:

```bash
cd ~/Documents/projects/homelab/networking

# Set environment variables
source .env

# Re-import from live infrastructure
terrifi generate-imports terrifi_network
terrifi generate-imports terrifi_wlan
terrifi generate-imports terrifi_firewall_zone
terrifi generate-imports terrifi_firewall_policy
terrifi generate-imports terrifi_dns_record
terrifi generate-imports terrifi_client_device

# Follow the import workflow in SPEC.md
```

## Service-Specific Recovery Notes

### Caddy (TLS Certificates)
Caddy automatically re-obtains certificates on startup. No manual recovery needed for TLS.

### AdGuard Home
DNS Rewrite rules and filter lists are stored in config. If restoring from backup, verify:
- DNS Rewrite `*.home.ncronquist.com` → Caddy IP
- Upstream DNS servers
- Filter lists

### Jellyfin
Media metadata and watch history are in the config. Media files are on the external SSD (not backed up by `backup.sh`).

### *arr Stack (Radarr, Sonarr, Prowlarr)
Database and configuration are in config. After restore:
- Verify download client connection (Transmission)
- Verify indexer connections (Prowlarr)
- Trigger library scan

### Gitea
Git repositories are stored in `./data/gitea/`. Ensure this is backed up — losing it means losing all hosted repos.

### Coder
PostgreSQL data is in `./data/coder-db/`. This contains workspace definitions, templates, and user data. Critical to back up.

## Backup Schedule

Consider automating backups:

```bash
# Add to crontab (daily at 3 AM)
crontab -e
0 3 * * * /path/to/homelab/docker/scripts/backup.sh /path/to/backup/destination
```
