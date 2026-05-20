# Runbook: Tailscale Split DNS for Remote Homelab Access

## Overview

This runbook configures remote access to all `*.home.ncronquist.com` services
from devices connected via Tailscale (iPads, thin clients, etc.).

**The problem it solves:** The homelab uses internal-only subdomains that only
resolve on the LAN (via UDM DNS A-records). When you're away from home using
Tailscale, your iPad has no way to know that `git.home.ncronquist.com` should
route to the MacBook.

**The solution:** Tailscale Split DNS tells remote Tailscale clients to use a
specific nameserver for queries in the `home.ncronquist.com` zone. That
nameserver is AdGuard Home, running in Docker on the MacBook.

```
Remote iPad (Tailscale)
  │
  ├─ DNS query: git.home.ncronquist.com
  │     ↓ Tailscale Split DNS
  ├─ Sent to: MacBook Tailscale IP (100.x.x.x), port 53
  │     ↓ AdGuard Home (listening on host port 53 via Tailscale interface)
  └─ Answer: 192.168.4.31
        ↓ Tailscale routes traffic to MacBook
  Caddy → gitea:3000 → Gitea web UI ✓
```

---

## Prerequisites

- [ ] Tailscale installed and connected on the MacBook (`tailscale ip -4` returns a `100.x.x.x` address)
- [ ] AdGuard Home container running (`docker compose ps adguard` shows `running`)
- [ ] Tailscale admin console access (https://login.tailscale.com/admin)

---

## Step 1 — Find the MacBook's Tailscale IP

```bash
tailscale ip -4
# Example output: 100.64.12.34
```

Note this IP — you will use it as the nameserver address in the Tailscale admin console.

---

## Step 2 — Configure AdGuard Home as a Local Resolver

AdGuard Home needs to listen for DNS on the MacBook's Tailscale interface and
return the correct IP for all `*.home.ncronquist.com` hostnames.

### 2a — Expose AdGuard DNS on the Tailscale Interface Only

By default (after the Fix 3 changes), AdGuard does NOT bind port 53 on the
host. We need to expose it **only** on the Tailscale interface so remote
Tailscale clients can reach it, without making it a public resolver.

Edit `docker/apps/adguard/compose.yml` and add the following port binding
(binding to the Tailscale interface IP only):

```yaml
services:
  adguard:
    ports:
      # Bind DNS only to the Tailscale interface — not 0.0.0.0
      # Replace 100.64.12.34 with your actual Tailscale IP (tailscale ip -4)
      - "100.64.12.34:53:53/tcp"
      - "100.64.12.34:53:53/udp"
      # Web UI via Caddy only (no direct host port needed)
```

> **Why this is safe:** Binding to the Tailscale IP means only devices on
> your Tailscale network can send DNS queries to this port. It's not exposed
> to the public internet or even your LAN.

Then apply the change:

```bash
cd docker
docker compose up -d adguard
```

### 2b — Configure AdGuard DNS Rewrites

1. Open AdGuard Home: `https://adguard.home.ncronquist.com`
2. Navigate to **Filters → DNS Rewrites**
3. Add a wildcard rewrite:
   - **Domain**: `*.home.ncronquist.com`
   - **Answer**: `192.168.4.31`
4. Click **Save**

This tells AdGuard to return the MacBook's LAN IP for any homelab subdomain query.

### 2c — Verify AdGuard is Answering

From the MacBook (while Tailscale is connected):

```bash
# Query AdGuard directly via the Tailscale IP
dig git.home.ncronquist.com @$(tailscale ip -4) +short
# Expected output: 192.168.4.31
```

---

## Step 3 — Configure Tailscale Split DNS

1. Open the Tailscale admin console: https://login.tailscale.com/admin/dns
2. Under **Nameservers**, click **Add nameserver** → **Custom**
3. Set:
   - **Nameserver**: `<your MacBook Tailscale IP>` (e.g., `100.64.12.34`)
   - **Restrict to domain**: ✅ checked
   - **Domain**: `home.ncronquist.com`
4. Click **Save**

> **What this does:** All Tailscale-connected devices will now route DNS queries
> for `*.home.ncronquist.com` to your MacBook's Tailscale IP, where AdGuard
> answers them. All other DNS queries continue to use whatever the device
> normally uses (e.g., `1.1.1.1`).

---

## Step 4 — Test from a Remote Device

Connect your iPad (or other device) to Tailscale, then:

```bash
# In a Shortcuts/terminal app on iPad, or SSH into another machine on Tailscale:
nslookup git.home.ncronquist.com
# Should return 192.168.4.31

# Then open in Safari:
# https://git.home.ncronquist.com  → should load Gitea
# https://coder.home.ncronquist.com → should load Coder
```

---

## Troubleshooting

### DNS query times out

```bash
# Check AdGuard container is running
docker ps | grep adguard

# Check AdGuard is listening on the Tailscale IP
sudo lsof -i @$(tailscale ip -4):53

# Check Tailscale can reach itself
ping $(tailscale ip -4)
```

### DNS resolves but page won't load

The DNS is working but Caddy isn't reachable. Check:

```bash
# Is Caddy running?
docker ps | grep caddy

# Can Caddy be reached on the Tailscale interface?
curl -v https://git.home.ncronquist.com --resolve git.home.ncronquist.com:443:$(tailscale ip -4)
```

If this works, you may need to also configure Caddy to listen on the Tailscale
interface. By default, OrbStack's Caddy container listens on all interfaces
(`0.0.0.0`), so it should be reachable at both the LAN IP and Tailscale IP.

### Split DNS not applying on device

- Ensure the device is connected to Tailscale (not just Wi-Fi)
- On iOS: Settings → VPN → Tailscale → verify it shows as Connected
- Wait ~30 seconds after connecting for DNS policies to propagate
- Toggle Tailscale off and back on if needed

---

## Architecture Diagram (Complete)

```
LOCAL NETWORK (at home)
┌─────────────────────────────────────────────┐
│  Any Device                                 │
│  DNS: *.home.ncronquist.com                │
│       → UDM native DNS → 192.168.4.31      │
│       → Caddy → Container                  │
└─────────────────────────────────────────────┘

REMOTE (Tailscale)
┌─────────────────────────────────────────────┐
│  iPad / Thin Client (Tailscale connected)   │
│  DNS: *.home.ncronquist.com                │
│       → Tailscale Split DNS                │
│       → AdGuard @ 100.x.x.x:53            │
│       → answers: 192.168.4.31              │
│  Traffic: → Tailscale → 100.x.x.x         │
│           → OrbStack → Caddy → Container   │
└─────────────────────────────────────────────┘
```
