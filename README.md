# Homelab

Monorepo for managing a homelab running on an M2 Max MacBook Pro (64GB RAM) with [OrbStack](https://orbstack.dev/), an external 4TB SSD for media storage, and a Unifi Dream Machine router for networking.

## Architecture Overview

All services run as Docker containers managed by Docker Compose, orchestrated through OrbStack on macOS. Caddy handles HTTPS termination with Let's Encrypt wildcard certificates via Cloudflare DNS-01 challenge. AdGuard Home provides DNS with local rewrites for `*.home.ncronquist.com`. Tailscale on the macOS host enables secure remote access to all services.

> For a detailed architecture breakdown, diagrams, and network topology, see [docs/architecture.md](docs/architecture.md).

## Projects

| Directory | Description | Tools |
|-----------|-------------|-------|
| [`networking/`](networking/) | Unifi network infrastructure configuration | Terraform / OpenTofu, Unifi provider |
| [`docker/`](docker/) | Docker Compose service definitions and configs | Docker Compose, OrbStack |

## Services

| Service | Subdomain | Description |
|---------|-----------|-------------|
| Jellyfin | `jellyfin.home.ncronquist.com` | Media server |
| Transmission | `transmission.home.ncronquist.com` | BitTorrent client |
| Radarr | `radarr.home.ncronquist.com` | Movie management |
| Sonarr | `sonarr.home.ncronquist.com` | TV show management |
| Prowlarr | `prowlarr.home.ncronquist.com` | Indexer management |
| Jellyseerr | `jellyseerr.home.ncronquist.com` | Media request management |
| AdGuard Home | `adguard.home.ncronquist.com` | DNS server & ad blocker |
| Uptime Kuma | `status.home.ncronquist.com` | Service monitoring |
| Beszel | `beszel.home.ncronquist.com` | System monitoring |
| Dozzle | `logs.home.ncronquist.com` | Docker log viewer |
| Calibre | `calibre.home.ncronquist.com` | E-book management |
| Calibre-Web | `books.home.ncronquist.com` | E-book web reader |
| Gitea | `git.home.ncronquist.com` | Self-hosted Git |
| Coder | `coder.home.ncronquist.com` | Cloud development environments |

## Prerequisites

- **macOS** (Apple Silicon)
- **[OrbStack](https://orbstack.dev/)** — Docker runtime for macOS
- **[Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/)** — Infrastructure as code for Unifi configuration
- **[Tailscale](https://tailscale.com/)** — VPN for secure remote access
- **[Cloudflare](https://www.cloudflare.com/) account** — DNS management and HTTPS certificates

## Getting Started

See the [Initial Setup Runbook](docs/runbooks/initial-setup.md) for step-by-step instructions to get everything running from scratch.

## Documentation

- [Architecture](docs/architecture.md) — System design, diagrams, and service topology
- [Networking](docs/networking.md) — Network topology, DNS, and HTTPS strategy

### Runbooks

- [Initial Setup](docs/runbooks/initial-setup.md) — First-time setup guide
- [Adding a Service](docs/runbooks/adding-a-service.md) — How to add a new service
- [Disaster Recovery](docs/runbooks/disaster-recovery.md) — Backup and recovery procedures

## Repository Structure

```
homelab/
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── networking.md
│   └── runbooks/
│       ├── initial-setup.md
│       ├── adding-a-service.md
│       └── disaster-recovery.md
├── docker/
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── scripts/
│   │   └── setup.sh
│   ├── apps/
│   │   ├── caddy/
│   │   ├── adguard/
│   │   ├── jellyfin/
│   │   ├── transmission/
│   │   ├── radarr/
│   │   ├── sonarr/
│   │   ├── prowlarr/
│   │   ├── jellyseerr/
│   │   ├── uptime-kuma/
│   │   ├── beszel/
│   │   ├── dozzle/
│   │   ├── calibre/
│   │   ├── calibre-web/
│   │   ├── gitea/
│   │   └── coder/
│   └── data/          # Runtime data (gitignored)
└── networking/
    ├── README.md
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars.example
```