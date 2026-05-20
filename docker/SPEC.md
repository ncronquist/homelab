# Docker Project — Specification

## Architecture

### Modular Compose Structure

The root `docker-compose.yml` uses the `include` directive to compose all service groups:

```yaml
include:
  - path: ./apps/caddy/compose.yml
  - path: ./apps/adguard/compose.yml
  - path: ./apps/media/compose.yml
  - path: ./apps/monitoring/compose.yml
  - path: ./apps/calibre/compose.yml
  - path: ./apps/gitea/compose.yml
  - path: ./apps/coder/compose.yml
```

Each included compose file is self-contained — you can `cd apps/media && docker compose up` independently for testing.

### Networking

- **`proxy` network** — A shared bridge network connecting Caddy to all services that need reverse proxying. Defined externally and referenced by each service group.
- **Internal networks** — Service groups can define internal networks for inter-service communication (e.g., `media` network for the *arr stack, `coder` network for Coder + PostgreSQL).

### Domain Routing

All services are accessed via `<service>.home.ncronquist.com`.
DNS resolution depends on where the client is connecting from:

**On the local network (LAN):**
1. **UDM** resolves `*.home.ncronquist.com` → `192.168.4.31` (MacBook LAN IP) via native DNS A-records (managed in `networking/dns.tf`)
2. **Caddy** (running in OrbStack) terminates TLS and reverse-proxies to the correct container

**Over Tailscale (remote):**
1. **Tailscale Split DNS** routes queries for `home.ncronquist.com` to the MacBook's Tailscale IP (`100.x.x.x`)
2. **AdGuard Home** (running in Docker) answers those DNS queries, returning `192.168.4.31` for all `*.home.ncronquist.com` hostnames
3. **Caddy** terminates TLS and reverse-proxies as usual

See `docs/runbooks/tailscale-split-dns.md` for the exact Tailscale admin console steps.

### HTTPS

- **Provider:** Let's Encrypt
- **Challenge:** DNS-01 via Cloudflare API (no inbound ports needed)
- **Certificate:** Wildcard cert for `*.home.ncronquist.com` and `*.coder.home.ncronquist.com`
- **Plugin:** Custom Caddy build with `caddy-dns/cloudflare`

### Tailscale

Tailscale runs on the host Mac (not in a container). The MacBook's Tailscale IP (`100.x.x.x`) is the remote access entrypoint. Tailscale Split DNS routes `home.ncronquist.com` queries from remote devices to AdGuard Home via the MacBook's Tailscale interface.

See `docs/runbooks/tailscale-split-dns.md` for complete setup instructions.

---

## Storage

### Config Data

Service configuration stored in `./apps/<group>/data/<service>/`:
- Persisted across container restarts
- Backed up by `scripts/backup.sh`
- Excluded from git via `.gitignore`

### Media Data

Media files stored on external SSD at `/Volumes/teamgroupqx/media/`:

```
/Volumes/teamgroupqx/media/
├── torrents/                    # Transmission downloads
├── movies/                      # Radarr → Jellyfin
├── tv/                          # Sonarr → Jellyfin
├── books/                       # Calibre library
└── Grandparent Video Files/     # Personal media
```

---

## Environment Variables

- Each service group has a `.env.example` template (committed to git)
- Copy to `.env` and fill in secrets (`.env` files are gitignored)
- Global variables (TZ, PUID, PGID) defined in `docker/.env.example`

---

## Service Inventory

| Service | Image | Internal Port | Subdomain | Network(s) |
|---|---|---|---|---|
| Caddy | Custom build | 80, 443 | — | proxy |
| AdGuard Home | `adguard/adguardhome` | 53, 3000 | adguard | proxy |
| Jellyfin | `jellyfin/jellyfin` | 8096 | jellyfin | proxy, media |
| TransmissionVPN | `magicalyak/transmissionvpn` | 9091 | transmission | proxy, media |
| Radarr | `linuxserver/radarr` | 7878 | radarr | proxy, media |
| Sonarr | `linuxserver/sonarr` | 8989 | sonarr | proxy, media |
| Prowlarr | `linuxserver/prowlarr` | 9696 | prowlarr | proxy, media |
| Jellyseerr | `fallenbagel/jellyseerr` | 5055 | jellyseerr | proxy, media |
| Recyclarr | `recyclarr/recyclarr` | — | — | media |
| Cleanuparr | `ghcr.io/cjmcquire/cleanuparr` | — | — | media |
| Uptime Kuma | `louislam/uptime-kuma` | 3001 | status | proxy |
| Beszel | `henrygd/beszel` | 8090 | beszel | proxy |
| Dozzle | `amir20/dozzle` | 8080 | logs | proxy |
| Calibre | `linuxserver/calibre` | 8080 | calibre | proxy |
| Calibre-Web | `linuxserver/calibre-web` | 8083 | books | proxy |
| Gitea | `gitea/gitea` | 3000 | git | proxy |
| Coder | `ghcr.io/coder/coder` | 7080 | coder | proxy, coder |
| Coder DB | `postgres:16-alpine` | 5432 | — | coder |

---

## Backup Strategy

### Backed Up (via `scripts/backup.sh`)

- Service configuration: `apps/*/data/`
- Docker compose files and Caddyfile
- Environment example files

### Not Backed Up

- Media files (too large; assumed to be on external SSD with its own backup strategy)
- Container images (re-pulled on restore)
- Docker volumes for certs (Caddy re-obtains certificates automatically)
