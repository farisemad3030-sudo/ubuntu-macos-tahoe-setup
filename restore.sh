#!/usr/bin/env bash
# Restore GNOME desktop settings from the most recent backup (or reset to defaults)

set -euo pipefail

BACKUP_DIR="$HOME/.config/macos-theme-backup"
LATEST_BACKUP="$(ls -t "$BACKUP_DIR"/dconf-backup-*.ini 2>/dev/null | head -n 1 || true)"

if [ -n "$LATEST_BACKUP" ]; then
  echo "==> Restoring dconf backup from: $LATEST_BACKUP"
  dconf load / < "$LATEST_BACKUP"
  echo "Done! Log out and log back in for all changes to take full effect."
else
  echo "No backup found in $BACKUP_DIR."
  echo "To reset GNOME interface/dock settings manually, run:"
  echo "  gsettings reset-recursively org.gnome.desktop.interface"
  echo "  gsettings reset-recursively org.gnome.shell.extensions.dash-to-dock"
fi
