# Caddy — Reverse Proxy + HTTPS

## Overview

Caddy serves as the reverse proxy and TLS termination point for all homelab services. It uses a custom Docker image with the Cloudflare DNS plugin to obtain wildcard Let's Encrypt certificates via the DNS-01 challenge.

## How HTTPS Works (Internal-Only)

1. Caddy uses the Cloudflare API to create a TXT record at `_acme-challenge.home.ncronquist.com`
2. Let's Encrypt validates domain ownership and issues a wildcard cert for `*.home.ncronquist.com`
3. No inbound ports need to be open to the internet — the challenge is purely DNS-based
4. Caddy auto-renews the certificate before expiry
5. All internal clients get trusted HTTPS with no browser warnings

## Configuration

| Item | Value |
|---|---|
| Image | Custom build (Caddy 2 + `caddy-dns/cloudflare`) |
| Ports | `80` (HTTP redirect), `443` (HTTPS), `443/udp` (HTTP/3) |
| Certificate | Wildcard `*.home.ncronquist.com` via Let's Encrypt |
| Network | `proxy` (shared with all proxied services) |

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Yes | Cloudflare API token with Zone:DNS:Edit and Zone:Zone:Read permissions |

### Creating the Cloudflare API Token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Create Token → Custom Token
3. Permissions:
   - Zone → DNS → Edit
   - Zone → Zone → Read
4. Zone Resources: Include → Specific zone → `ncronquist.com`

## Files

- `Dockerfile` — Custom Caddy build with Cloudflare DNS plugin
- `Caddyfile` — Reverse proxy configuration for all services
- `compose.yml` — Docker Compose service definition

## Testing

When first setting up, uncomment the Let's Encrypt staging CA in the Caddyfile to avoid rate limits:

```caddy
{
    acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}
```

Remove this line once everything is working to get real certificates.

## Volumes

- `caddy_data` — Certificate storage (persisted across restarts)
- `caddy_config` — Caddy configuration cache
