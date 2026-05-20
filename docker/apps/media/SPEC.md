# Media Stack — Specification

## Overview

Complete media server stack for movie and TV show management, streaming, and automated downloading.

## Services

| Service | Image | Subdomain | Port | Purpose |
|---|---|---|---|---|
| Jellyfin | `jellyfin/jellyfin` | `jellyfin.home.ncronquist.com` | 8096 | Media streaming server |
| TransmissionVPN | `magicalyak/transmissionvpn` | `transmission.home.ncronquist.com` | 9091 | Torrent client with PIA VPN |
| Radarr | `linuxserver/radarr` | `radarr.home.ncronquist.com` | 7878 | Movie management & automation |
| Sonarr | `linuxserver/sonarr` | `sonarr.home.ncronquist.com` | 8989 | TV show management & automation |
| Prowlarr | `linuxserver/prowlarr` | `prowlarr.home.ncronquist.com` | 9696 | Indexer management |
| Jellyseerr | `fallenbagel/jellyseerr` | `jellyseerr.home.ncronquist.com` | 5055 | Media request & discovery UI |
| Recyclarr | `recyclarr/recyclarr` | — | — | TRaSH guide sync (no UI) |
| Cleanuparr | `ghcr.io/cjmcquire/cleanuparr` | — | — | Auto-cleanup (no UI) |

## Data Flow

```
User Request (Jellyseerr)
  → Radarr/Sonarr (search & manage)
    → Prowlarr (indexer queries)
      → TransmissionVPN (download via PIA VPN)
        → /Volumes/teamgroupqx/media/torrents/
  → Radarr/Sonarr (import & organize)
    → /Volumes/teamgroupqx/media/movies/ or tv/
      → Jellyfin (stream)
```

## Storage Layout

### External SSD (`${MEDIA_PATH}` → `/Volumes/teamgroupqx/media/`)

All media containers mount the external SSD root as `/data` — a single, unified mountpoint. This is a deliberate design choice:

**Why a unified `/data` mount?**
Radarr and Sonarr need to see both the torrent download directory and the final media library on the **same filesystem** inside the container. When both are under `/data`, post-processing is an atomic rename (hardlink), not a cross-device file copy. This is:
- ⚡ **Instant** — no data is duplicated on disk
- 🔒 **Safe** — no window where the file exists in neither location
- 💾 **Space-efficient** — hardlinks share blocks until one is modified

If download and destination were on different mounts (e.g., `/downloads` and `/movies`), the *arr apps would fall back to a slow, disk-filling copy-then-delete.

| Path inside container | Physical path | Used by |
|---|---|---|
| `/data/torrents/` | `…/media/torrents/` | Transmission (write), Radarr, Sonarr (read) |
| `/data/movies/` | `…/media/movies/` | Radarr (write), Jellyfin (read) |
| `/data/tv/` | `…/media/tv/` | Sonarr (write), Jellyfin (read) |
| `/data/.cache/jellyfin/` | `…/media/.cache/jellyfin/` | Jellyfin transcoding cache |
| `/data/books/` | `…/media/books/` | Calibre library |

**Jellyfin** mounts `/data` as **read-only** (`ro`) since it only streams.
**Transmission** and the *arr apps mount `/data` read-write for import/move operations.

> ⚠️ **After switching to the unified mount**, you must reconfigure the paths
> inside each app's web UI:
> - Radarr: Settings → Media Management → Root Folder → `/data/movies`
> - Radarr: Settings → Download Clients → Remote Path Mapping → `/data/torrents`
> - Sonarr: Settings → Media Management → Root Folder → `/data/tv`
> - Sonarr: Settings → Download Clients → Remote Path Mapping → `/data/torrents`
> - Jellyfin: Dashboard → Libraries → use `/data/movies` and `/data/tv`

## Networking

- **proxy** (external) — Connects UI services to Caddy for HTTPS reverse proxying
- **media** (internal) — Inter-service communication (Radarr ↔ Transmission, etc.)

## TransmissionVPN Configuration

TransmissionVPN routes all torrent traffic through PIA VPN:

- `VPN_PROVIDER=PIA`
- `VPN_USERNAME` / `VPN_PASSWORD` — Your PIA credentials
- `LOCAL_NETWORK=192.168.4.0/24` — Allows LAN access to the web UI
- `cap_add: NET_ADMIN` — Required for VPN tunnel creation
- IPv6 disabled via sysctl for VPN compatibility

## Service Dependencies

```
Prowlarr (standalone — configure first)
  ↓
TransmissionVPN (standalone — configure VPN first)
  ↓
Radarr (depends on Transmission for downloads)
Sonarr (depends on Transmission for downloads)
  ↓
Jellyfin (reads organized media)
  ↓
Jellyseerr (depends on Jellyfin for library info)
```

## Setup Order

1. Start TransmissionVPN — verify VPN is connected
2. Start Prowlarr — add indexers
3. Start Radarr — connect to Prowlarr and Transmission
4. Start Sonarr — connect to Prowlarr and Transmission
5. Start Jellyfin — add movie and TV library paths
6. Start Jellyseerr — connect to Jellyfin
7. Start Recyclarr — configure TRaSH guide sync
8. Start Cleanuparr — configure cleanup rules
