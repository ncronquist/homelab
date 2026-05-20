# Initial Setup — Runbook

Step-by-step guide for setting up the homelab from scratch.

## Prerequisites

Install on your Mac:

1. **OrbStack** — Docker runtime for macOS
   ```bash
   brew install orbstack
   ```

2. **Terraform** (or OpenTofu) — For networking configuration
   ```bash
   brew install terraform
   # or: brew install opentofu
   ```

3. **Tailscale** — For remote access
   ```bash
   brew install tailscale
   ```

4. **Cloudflare account** — For DNS and HTTPS certificates

## Step 1: Clone the Repo

```bash
git clone <repo-url> ~/Documents/projects/homelab
cd ~/Documents/projects/homelab
```

## Step 2: Migrate DNS to Cloudflare

> **Important:** This must be done before HTTPS certificates can be issued.

1. **Create a Cloudflare account** at https://dash.cloudflare.com
2. **Add your domain** `ncronquist.com` to Cloudflare
3. **Replicate all DNS records** from Squarespace, especially:
   - **MX records** for email forwarding to Gmail (critical!)
   - A/CNAME records for GitHub Pages
   - Any other existing records
4. **Update nameservers** at your domain registrar to point to Cloudflare
5. **Wait for propagation** (can take up to 48 hours)
6. **Verify email** still works after migration
7. **Create API token** for Caddy:
   - Dash → Profile → API Tokens → Create Token
   - Permissions: Zone:DNS:Edit, Zone:Zone:Read
   - Zone: ncronquist.com only

## Step 3: Connect External SSD

Ensure the 4TB SSD is mounted at `/Volumes/teamgroupqx` with the media directory structure:

```
/Volumes/teamgroupqx/media/
├── torrents/
├── movies/
├── tv/
├── books/
└── Grandparent Video Files/
```

## Step 4: Configure Environment Variables

```bash
cd docker

# Copy global .env
cp .env.example .env

# Copy per-service .env files
for dir in apps/*/; do
  if [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
  fi
done
```

Edit each `.env` file and fill in your secrets:

| File | Key Variables |
|---|---|
| `docker/.env` | TZ, PUID, PGID |
| `apps/caddy/.env` | `CLOUDFLARE_API_TOKEN` |
| `apps/media/.env` | `VPN_USERNAME`, `VPN_PASSWORD` |
| `apps/coder/.env` | `CODER_DB_PASSWORD` |

## Step 5: Run Setup Script

```bash
./scripts/setup.sh
```

This creates Docker networks, data directories, and validates your configuration.

## Step 6: Start Core Infrastructure

Start Caddy and AdGuard Home first:

```bash
docker compose up -d caddy adguard
```

### Configure AdGuard Home

1. Open `http://localhost:3000` for the setup wizard
2. Set admin credentials
3. After setup, add DNS Rewrite:
   - Domain: `*.home.ncronquist.com`
   - Answer: `<your-mac-ip>` (e.g., `192.168.1.100`)
4. Set upstream DNS: `1.1.1.1`, `9.9.9.9`

## Step 7: Configure UDM Router

In the UniFi controller:

1. Settings → Networks → select your network
2. DHCP Name Server → Manual
3. Enter the Mac's IP address (where AdGuard Home runs)
4. Save

Now all network clients will use AdGuard Home for DNS.

## Step 8: Verify HTTPS

```bash
# Test DNS resolution
dig jellyfin.home.ncronquist.com

# Test HTTPS (after Caddy obtains certificates)
curl -I https://jellyfin.home.ncronquist.com
```

## Step 9: Start Remaining Services

```bash
# Start everything
docker compose up -d

# Or start groups individually
docker compose up -d jellyfin transmission radarr sonarr prowlarr jellyseerr
docker compose up -d uptime-kuma beszel dozzle
docker compose up -d calibre calibre-web
docker compose up -d gitea
docker compose up -d coder-db coder
```

## Step 10: Configure Tailscale

1. Sign in to Tailscale on your Mac
2. All services are now accessible remotely via your Mac's Tailscale IP
3. Access any service at `https://<service>.home.ncronquist.com` from any Tailscale-connected device

> **Note:** Remote devices need to use your AdGuard Home or configure DNS manually to resolve `*.home.ncronquist.com`.

## Step 11: Configure Services

Each service needs initial configuration through its web UI. Follow the setup order in [media/SPEC.md](../../docker/apps/media/SPEC.md):

1. TransmissionVPN — verify VPN connection
2. Prowlarr — add indexers
3. Radarr — connect to Prowlarr + Transmission
4. Sonarr — connect to Prowlarr + Transmission
5. Jellyfin — add media libraries
6. Jellyseerr — connect to Jellyfin
