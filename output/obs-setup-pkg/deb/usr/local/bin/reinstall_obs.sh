#!/bin/bash
set -e

CONFIG_DIR="$HOME/.config/obs-studio"
BACKUP_DIR="$HOME/obs-studio-config-backup-$(date +%Y%m%d-%H%M%S)"

echo "🔄 Starting OBS Studio reinstallation..."

# Backup config if it exists
if [ -d "$CONFIG_DIR" ]; then
    echo "💾 Backing up your OBS Studio config to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
else
    echo "ℹ️ No existing OBS Studio config found, skipping backup."
fi

# Run uninstall script
if [ -x "./uninstall_obs.sh" ]; then
    echo "🗑️ Running uninstall script..."
    ./uninstall_obs.sh
else
    echo "❌ uninstall_obs.sh script not found or not executable."
    exit 1
fi

# Run install script
if [ -x "./install_obs.sh" ]; then
    echo "⬆️ Running install script..."
    ./install_obs.sh
else
    echo "❌ install_obs.sh script not found or not executable."
    exit 1
fi

echo "🎉 OBS Studio reinstalled successfully!"

# Restore config prompt
if [ -d "$BACKUP_DIR" ]; then
    read -rp "Restore your OBS config from backup? (y/N): " restore
    if [[ "$restore" =~ ^[Yy]$ ]]; then
        echo "♻️ Restoring config..."
        rm -rf "$CONFIG_DIR"
        cp -r "$BACKUP_DIR/obs-studio" "$CONFIG_DIR"
        echo "✅ Config restored."
    else
        echo "⚠️ Config not restored. Backup is at $BACKUP_DIR"
    fi
fi

exit 0

