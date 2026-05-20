# Calibre — E-book Management

## Overview

Calibre provides a complete self-hosted e-book management solution consisting of two complementary services:

- **Calibre**: Full-featured library management with a desktop-like UI accessible via a web browser. Used for importing, organizing, converting, and managing e-books.
- **Calibre-Web**: A polished, read-only browsing and reading interface for the same library. Optimized for discovering and reading books from any device.

Both services share the same book library stored on an external SSD, with Calibre acting as the primary manager and Calibre-Web providing a clean reading experience.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Caddy (Reverse Proxy)              │
│  calibre.home.ncronquist.com → calibre:8080          │
│  books.home.ncronquist.com   → calibre-web:8083      │
└──────────────┬──────────────────────┬────────────────┘
               │                      │
        ┌──────▼──────┐       ┌───────▼───────┐
        │   Calibre   │       │  Calibre-Web  │
        │  (Manager)  │       │   (Reader)    │
        │  Port 8080  │       │  Port 8083    │
        └──────┬──────┘       └───────┬───────┘
               │ read/write           │ read-only
               │                      │
        ┌──────▼──────────────────────▼───────┐
        │   /Volumes/teamgroupqx/media/books  │
        │         (External SSD)              │
        └─────────────────────────────────────┘
```

## Services

### Calibre

| Property        | Value                                          |
| --------------- | ---------------------------------------------- |
| Image           | `linuxserver/calibre:latest`                   |
| Container name  | `calibre`                                      |
| Subdomain       | `calibre.home.ncronquist.com`                  |
| Internal port   | `8080` (web UI), `8181` (desktop UI via HTTPS) |
| Config volume   | `./data/calibre:/config`                       |
| Books volume    | `/Volumes/teamgroupqx/media/books:/books`      |
| Network         | `proxy` (external, shared with Caddy)          |
| Restart policy  | `unless-stopped`                               |

**Purpose**: Import, organize, edit metadata, convert formats, and manage the entire e-book library. The web UI provides a desktop-like experience accessible from any browser.

### Calibre-Web

| Property        | Value                                               |
| --------------- | --------------------------------------------------- |
| Image           | `linuxserver/calibre-web:latest`                    |
| Container name  | `calibre-web`                                       |
| Subdomain       | `books.home.ncronquist.com`                         |
| Internal port   | `8083`                                              |
| Config volume   | `./data/calibre-web:/config`                        |
| Books volume    | `/Volumes/teamgroupqx/media/books:/books:ro`        |
| Network         | `proxy` (external, shared with Caddy)               |
| Restart policy  | `unless-stopped`                                    |
| Depends on      | `calibre`                                           |
| Docker mod      | `linuxserver/mods:universal-calibre` (ebook convert) |

**Purpose**: Provides a modern, responsive web interface for browsing and reading books. Mounts the book library as read-only since all management is done through the Calibre container.

The `universal-calibre` Docker mod installs Calibre binaries inside the Calibre-Web container, enabling server-side e-book format conversion (e.g., EPUB → MOBI) directly from the Calibre-Web UI.

## Storage

### Book Library

- **Path**: `/Volumes/teamgroupqx/media/books/`
- **Description**: External SSD housing the Calibre library (books, metadata, covers)
- **Access**: Read/write from Calibre, read-only from Calibre-Web
- **Note**: The Calibre library database (`metadata.db`) lives inside this directory

### Configuration Data

- **Calibre config**: `./data/calibre/` — Calibre preferences, plugins, and session state
- **Calibre-Web config**: `./data/calibre-web/` — Calibre-Web settings, user database, and cache

## Networking

Both services connect to the `proxy` network (external), which is shared with the Caddy reverse proxy. No ports are exposed directly to the host — all access is through Caddy.

### Caddy Configuration

Add the following to your Caddy configuration:

```
calibre.home.ncronquist.com {
    reverse_proxy calibre:8080
}

books.home.ncronquist.com {
    reverse_proxy calibre-web:8083
}
```

## Environment Variables

| Variable | Default              | Description              |
| -------- | -------------------- | ------------------------ |
| `TZ`     | `America/Los_Angeles`| Container timezone       |
| `PUID`   | `501`                | User ID for file perms   |
| `PGID`   | `20`                 | Group ID for file perms  |

## Initial Setup

1. Start the stack: `docker compose up -d`
2. Access Calibre at `https://calibre.home.ncronquist.com`
3. On first launch, Calibre will create a library in `/books` if one does not exist
4. Access Calibre-Web at `https://books.home.ncronquist.com`
5. In Calibre-Web's initial setup, set the Calibre database path to `/books`
6. Default Calibre-Web credentials: `admin` / `admin123` (change immediately)

## Backup Considerations

- **Book library**: Back up `/Volumes/teamgroupqx/media/books/` — contains all books and metadata
- **Calibre config**: Back up `./data/calibre/` — contains preferences and plugins
- **Calibre-Web config**: Back up `./data/calibre-web/` — contains user accounts and settings
