# Docker — Homelab Services

All homelab services run as Docker containers via [OrbStack](https://orbstack.dev/) on macOS.

## Architecture

The stack uses a **modular structure** with Docker Compose's `include` directive. Each service group lives in its own directory under `apps/` with its own `compose.yml`, `SPEC.md`, and `.env.example`.

```
docker/
├── docker-compose.yml          # Root — includes all service groups
├── .env.example                # Global environment variables
├── apps/
│   ├── caddy/                  # Reverse proxy + HTTPS
│   ├── adguard/                # DNS + ad blocking
│   ├── media/                  # Jellyfin, *arr stack, Transmission
│   ├── monitoring/             # Uptime Kuma, Beszel, Dozzle
│   ├── calibre/                # E-book management
│   ├── gitea/                  # Git server
│   └── coder/                  # Development environments
└── scripts/
    ├── setup.sh                # First-time setup
    └── backup.sh               # Config data backup
```

## Services

| Service | Subdomain | Purpose |
|---|---|---|
| Caddy | — | Reverse proxy, automatic HTTPS |
| AdGuard Home | `adguard.home.ncronquist.com` | DNS server + ad blocking |
| Jellyfin | `jellyfin.home.ncronquist.com` | Media streaming |
| Transmission | `transmission.home.ncronquist.com` | Torrent client (with PIA VPN) |
| Radarr | `radarr.home.ncronquist.com` | Movie management |
| Sonarr | `sonarr.home.ncronquist.com` | TV show management |
| Prowlarr | `prowlarr.home.ncronquist.com` | Indexer management |
| Jellyseerr | `jellyseerr.home.ncronquist.com` | Media requests |
| Uptime Kuma | `status.home.ncronquist.com` | Uptime monitoring |
| Beszel | `beszel.home.ncronquist.com` | System metrics |
| Dozzle | `logs.home.ncronquist.com` | Container logs |
| Calibre | `calibre.home.ncronquist.com` | E-book library management |
| Calibre-Web | `books.home.ncronquist.com` | E-book reading UI |
| Gitea | `git.home.ncronquist.com` | Git hosting |
| Coder | `coder.home.ncronquist.com` | Dev environments |

## Quick Start

```bash
# 1. Copy environment files
cp .env.example .env
for dir in apps/*/; do
  if [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
  fi
done

# 2. Edit .env files with your secrets

# 3. Run setup script
./scripts/setup.sh

# 4. Start all services
docker compose up -d

# 5. Start a specific service group
docker compose up -d caddy adguard
```

See [SPEC.md](./SPEC.md) for detailed specifications.
