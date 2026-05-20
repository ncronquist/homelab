# Monitoring Stack — Specification

## Overview

Lightweight monitoring trio that covers ~90% of homelab monitoring needs at ~10% of the complexity of a full Prometheus + Grafana stack. All three services combined use less than 200MB RAM.

## Services

| Service | Image | Subdomain | Port | Purpose |
|---|---|---|---|---|
| Uptime Kuma | `louislam/uptime-kuma` | `status.home.ncronquist.com` | 3001 | "Is it up?" endpoint monitoring |
| Beszel | `henrygd/beszel` | `beszel.home.ncronquist.com` | 8090 | Host + container resource metrics |
| Dozzle | `amir20/dozzle` | `logs.home.ncronquist.com` | 8080 | Real-time container log streaming |

## Uptime Kuma

Monitors HTTP/TCP/DNS endpoints and provides:
- Status pages (shareable)
- Notification integrations (Discord, Telegram, email, etc.)
- Response time graphs
- Certificate expiry monitoring

**Setup:** Add monitors for each service endpoint (e.g., `https://jellyfin.home.ncronquist.com`).

## Beszel

Lightweight agent-based monitoring:
- Auto-discovers Docker containers
- CPU, RAM, disk, network metrics with history
- Extremely low resource usage (~10MB agent RAM)

**Setup:** Docker socket access provides container discovery automatically.

## Dozzle

Real-time container log streaming:
- Web-based log viewer (no SSH needed)
- Filter by container, search within logs
- Multi-container log merging

**Setup:** Docker socket access (read-only) is all that's needed.

## Docker Socket Access

Both Beszel and Dozzle require read-only access to the Docker socket:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

This is standard for monitoring tools and provides read-only container metadata.

## Future Enhancement

If you need more advanced monitoring (custom dashboards, PromQL queries, long-term retention), consider adding:
- Prometheus or VictoriaMetrics for metrics collection
- Grafana for dashboards
- These can supplement rather than replace the existing lightweight stack
