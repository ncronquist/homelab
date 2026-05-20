#!/usr/bin/env bash
# setup.sh — First-time setup for the homelab Docker environment
#
# Usage: ./scripts/setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🏠 Homelab Docker Setup"
echo "========================"
echo ""

# ---------------------------------------------------------------------------
# 1. Check prerequisites
# ---------------------------------------------------------------------------
echo "📋 Checking prerequisites..."

if ! command -v docker &>/dev/null; then
    echo "❌ Docker not found. Install OrbStack: https://orbstack.dev/"
    exit 1
fi

if ! docker info &>/dev/null; then
    echo "❌ Docker daemon not running. Start OrbStack first."
    exit 1
fi

echo "✅ Docker is available"

# Check for external SSD
if [ ! -d "/Volumes/teamgroupqx/media" ]; then
    echo "⚠️  External SSD not found at /Volumes/teamgroupqx/media"
    echo "   Media services will fail to start without it."
    echo "   Connect the SSD and try again, or continue without media services."
    read -p "   Continue anyway? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    # Create the Jellyfin transcoding cache directory on the SSD.
    # This prevents Jellyfin from filling the internal drive with HLS segments.
    mkdir -p /Volumes/teamgroupqx/media/.cache/jellyfin
    echo "✅ Jellyfin cache directory ready at /Volumes/teamgroupqx/media/.cache/jellyfin"
fi

# ---------------------------------------------------------------------------
# 2. Create Docker network
# ---------------------------------------------------------------------------
echo ""
echo "🌐 Creating Docker networks..."

if docker network inspect proxy &>/dev/null; then
    echo "✅ Network 'proxy' already exists"
else
    docker network create proxy
    echo "✅ Created network 'proxy'"
fi

# ---------------------------------------------------------------------------
# 3. Create data directories
# ---------------------------------------------------------------------------
echo ""
echo "📁 Creating data directories..."

DATA_DIRS=(
    "apps/caddy/data"
    "apps/adguard/data/work"
    "apps/adguard/data/conf"
    "apps/media/data/jellyfin/config"
    "apps/media/data/transmission"
    "apps/media/data/radarr"
    "apps/media/data/sonarr"
    "apps/media/data/prowlarr"
    "apps/media/data/jellyseerr"
    "apps/media/data/recyclarr"
    "apps/media/data/cleanuparr"
    "apps/monitoring/data/uptime-kuma"
    "apps/monitoring/data/beszel"
    "apps/calibre/data/calibre"
    "apps/calibre/data/calibre-web"
    # NOTE: apps/gitea/data/gitea is NOT here — Gitea uses a Docker named volume (gitea_data)
    # NOTE: apps/coder/data/coder-db is NOT here — Coder DB uses a Docker named volume (coder_db_data)
)

for dir in "${DATA_DIRS[@]}"; do
    mkdir -p "$DOCKER_DIR/$dir"
done

echo "✅ Data directories created"

# ---------------------------------------------------------------------------
# 4. Pre-create named volumes for critical services
# ---------------------------------------------------------------------------
# Gitea and Coder use Docker named volumes instead of bind-mounts.
# Creating them explicitly before `docker compose up` ensures they exist
# and are labelled correctly even if compose is run in a partial state.
echo ""
echo "📦 Pre-creating Docker named volumes for critical services..."

for vol in gitea_data coder_db_data coder_config_data; do
    if docker volume inspect "$vol" &>/dev/null; then
        echo "✅ Volume '$vol' already exists"
    else
        docker volume create "$vol"
        echo "✅ Created volume '$vol'"
    fi
done

# ---------------------------------------------------------------------------
# 5. Check for .env files
# ---------------------------------------------------------------------------
echo ""
echo "🔐 Checking environment files..."

MISSING_ENV=0
for env_example in "$DOCKER_DIR"/.env.example "$DOCKER_DIR"/apps/*/.env.example; do
    if [ -f "$env_example" ]; then
        env_file="${env_example%.example}"
        if [ ! -f "$env_file" ]; then
            echo "⚠️  Missing: ${env_file#$DOCKER_DIR/}"
            echo "   Copy from: ${env_example#$DOCKER_DIR/}"
            MISSING_ENV=1
        fi
    fi
done

if [ "$MISSING_ENV" -eq 1 ]; then
    echo ""
    echo "📝 Copy .env.example files to .env and fill in your secrets:"
    echo ""
    echo "   cd $DOCKER_DIR"
    echo "   cp .env.example .env"
    echo "   for dir in apps/*/; do"
    echo "     if [ -f \"\$dir/.env.example\" ]; then"
    echo "       cp \"\$dir/.env.example\" \"\$dir/.env\""
    echo "     fi"
    echo "   done"
    echo ""
else
    echo "✅ All .env files present"
fi

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------
echo ""
echo "========================"
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Fill in your .env files with secrets"
echo "  2. Start all services:  cd $DOCKER_DIR && docker compose up -d"
echo "  3. Or start specific:   docker compose up -d caddy gitea coder"
echo ""
echo "  DNS is managed by the UDM (Terraform in networking/). All"
echo "  *.home.ncronquist.com subdomains resolve to 192.168.4.31."
echo ""
echo "  For remote access (Tailscale): see docs/runbooks/tailscale-split-dns.md"
