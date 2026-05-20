#!/usr/bin/env bash
# backup.sh — Backup homelab service configuration data
#
# Usage: ./scripts/backup.sh [backup-destination]
#
# Backs up all service config data (docker/apps/*/data/).
# Excludes media files (too large; assumed to be on external SSD).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DEST="${1:-$DOCKER_DIR/backups}"
BACKUP_FILE="$BACKUP_DEST/homelab-config-$TIMESTAMP.tar.gz"

echo "🏠 Homelab Config Backup"
echo "========================"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DEST"

echo "📦 Backing up service configuration data..."
echo "   Source: $DOCKER_DIR/apps/*/data/"
echo "   Destination: $BACKUP_FILE"
echo ""

# Collect all data directories
DATA_DIRS=()
for data_dir in "$DOCKER_DIR"/apps/*/data; do
    if [ -d "$data_dir" ]; then
        # Get relative path from DOCKER_DIR
        REL_PATH="${data_dir#$DOCKER_DIR/}"
        DATA_DIRS+=("$REL_PATH")
        echo "   📁 $REL_PATH"
    fi
done

if [ ${#DATA_DIRS[@]} -eq 0 ]; then
    echo "⚠️  No data directories found. Nothing to back up."
    exit 0
fi

echo ""

# Create tarball
cd "$DOCKER_DIR"
tar -czf "$BACKUP_FILE" "${DATA_DIRS[@]}"

# Report size
BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
echo "✅ Backup complete!"
echo "   File: $BACKUP_FILE"
echo "   Size: $BACKUP_SIZE"
echo ""

# Cleanup old backups (keep last 5)
BACKUP_COUNT=$(ls -1 "$BACKUP_DEST"/homelab-config-*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 5 ]; then
    echo "🧹 Cleaning up old backups (keeping last 5)..."
    ls -1t "$BACKUP_DEST"/homelab-config-*.tar.gz | tail -n +6 | while read -r old_backup; do
        echo "   Removing: $(basename "$old_backup")"
        rm "$old_backup"
    done
fi
