# AdGuard Home — DNS + Ad Blocking

## Overview

AdGuard Home provides network-wide DNS resolution and ad blocking. It serves as the primary DNS server for all devices on the network.

## Configuration

| Item | Value |
|---|---|
| Image | `adguard/adguardhome:latest` |
| Subdomain | `adguard.home.ncronquist.com` |
| Ports | `53/tcp`, `53/udp` (DNS), `3000` (web UI / initial setup) |
| Network | `proxy` |

## Key Setup Steps

### 1. Initial Setup

On first run, access the setup wizard at `http://<host-ip>:3000` and configure:
- Admin username and password
- DNS listen address: `0.0.0.0:53`
- Web interface port: `3000`

### 2. DNS Rewrites

After initial setup, add a DNS Rewrite rule to resolve all homelab subdomains to Caddy:

- **Domain:** `*.home.ncronquist.com`
- **Answer:** `<host-ip>` (the IP of the Docker host where Caddy runs)

This ensures all `*.home.ncronquist.com` requests are routed to Caddy for reverse proxying.

### 3. Upstream DNS Servers

Configure upstream DNS servers for all other queries:
- `1.1.1.1` (Cloudflare)
- `9.9.9.9` (Quad9)
- `8.8.8.8` (Google, backup)

### 4. UDM Router Configuration

In the UniFi controller:
1. Settings → Networks → select network
2. DHCP Name Server → Manual
3. Enter the AdGuard Home container's IP address
4. This makes all network clients use AdGuard Home for DNS

## Data

- Config: `./data/conf/` — AdGuard Home configuration
- Work: `./data/work/` — Runtime data, query logs
