#!/usr/bin/env bash
# Ubuntu 26.04 (GNOME 50) -> macOS 26 Tahoe Dark Glass Transformation
# Reproduces the full theme, icons, cursors, fonts, wallpapers, extensions,
# Firefox Safari theme, Ptyxis terminal theme, Alt+Tab, Alt+Space Spotlight,
# and unified Tahoe Dark Glass CSS.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$HOME/.local/share/macos-theme-src"
BACKUP_DIR="$HOME/.config/macos-theme-backup"

echo "==> [1/9] Backing up existing GNOME dconf settings..."
mkdir -p "$BACKUP_DIR" "$SRC_DIR/extensions"
BACKUP_FILE="$BACKUP_DIR/dconf-backup-$(date +%Y%m%d-%H%M%S).ini"
dconf dump / > "$BACKUP_FILE"
echo "    Saved backup to: $BACKUP_FILE"

echo "==> [2/9] Installing APT prerequisites (will ask for sudo password)..."
sudo apt update
sudo apt install -y \
  git \
  curl \
  sassc \
  libglib2.0-dev-bin \
  libxml2-utils \
  gnome-tweaks \
  gnome-shell-extensions \
  gnome-shell-extension-manager

echo "==> [3/9] Cloning / updating MacTahoe themes, icons, cursors, and SF Pro fonts..."
clone_or_pull() {
  local repo="$1"
  local dest="$2"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only || true
  else
    git clone --depth=1 "$repo" "$dest"
  fi
}

clone_or_pull "https://github.com/vinceliuice/MacTahoe-gtk-theme.git" "$SRC_DIR/MacTahoe-gtk-theme"
clone_or_pull "https://github.com/vinceliuice/MacTahoe-icon-theme.git" "$SRC_DIR/MacTahoe-icon-theme"
clone_or_pull "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git" "$SRC_DIR/SF-Pro-Fonts"

echo "==> [4/9] Installing MacTahoe GTK/Shell theme (Light + Dark Liquid Glass + libadwaita + Firefox)..."
(
  cd "$SRC_DIR/MacTahoe-gtk-theme"
  git checkout -- . && git clean -fd
  ./install.sh -c light -c dark -o normal -b --shell -i apple
  ./install.sh -c dark -o normal -b -l
  ./tweaks.sh -f || true
)

# Keep GTK3 & GTK4 unfocused window buttons visibly colored instead of blank grey circles
for css in "$HOME/.themes/MacTahoe-Dark/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk-Dark.css"; do
  if [ -f "$css" ]; then
    sed -i \
      -e 's/titlebutton-close-backdrop-dark\.png/titlebutton-close-dark.png/g' \
      -e 's/titlebutton-close-backdrop-dark@2\.png/titlebutton-close-dark@2.png/g' \
      -e 's/titlebutton-maximize-backdrop-dark\.png/titlebutton-maximize-dark.png/g' \
      -e 's/titlebutton-maximize-backdrop-dark@2\.png/titlebutton-maximize-dark@2.png/g' \
      -e 's/titlebutton-minimize-backdrop-dark\.png/titlebutton-minimize-dark.png/g' \
      -e 's/titlebutton-minimize-backdrop-dark@2\.png/titlebutton-minimize-dark@2.png/g' \
      "$css"
  fi
done

echo "==> [5/9] Installing MacTahoe Icons, Cursors, Wallpapers, and SF Pro Fonts..."
(cd "$SRC_DIR/MacTahoe-icon-theme" && ./install.sh)
(cd "$SRC_DIR/MacTahoe-icon-theme/cursors" && ./install.sh)

mkdir -p "$HOME/.local/share/backgrounds/MacTahoe"
cp "$SRC_DIR/MacTahoe-gtk-theme/wallpaper/MacTahoe-day.jpeg" "$HOME/.local/share/backgrounds/MacTahoe/"
cp "$SRC_DIR/MacTahoe-gtk-theme/wallpaper/MacTahoe-night.jpeg" "$HOME/.local/share/backgrounds/MacTahoe/"

mkdir -p "$HOME/.local/share/fonts/SF-Pro"
cp "$SRC_DIR/SF-Pro-Fonts"/*.otf "$HOME/.local/share/fonts/SF-Pro/" 2>/dev/null || true
cp "$SRC_DIR/SF-Pro-Fonts"/*.ttf "$HOME/.local/share/fonts/SF-Pro/" 2>/dev/null || true
fc-cache -f "$HOME/.local/share/fonts"

echo "==> [6/9] Patching Snap .desktop launchers so Snap apps use MacTahoe icons..."
mkdir -p "$HOME/.local/share/applications"
patch_snap_desktop() {
  local src="/var/lib/snapd/desktop/applications/$1"
  local dst="$HOME/.local/share/applications/$1"
  local icon="$2"
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    sed -i "s|^Icon=.*|Icon=$icon|" "$dst"
  fi
}
patch_snap_desktop "firefox_firefox.desktop" "firefox"
patch_snap_desktop "thunderbird_thunderbird.desktop" "thunderbird"
patch_snap_desktop "snap-store_snap-store.desktop" "software-center"
patch_snap_desktop "desktop-security-center_desktop-security-center.desktop" "preferences-system-privacy"
patch_snap_desktop "firmware-updater_firmware-updater.desktop" "system-software-update"
patch_snap_desktop "firmware-updater_firmware-updater-app.desktop" "system-software-update"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache -f "$HOME/.local/share/icons/MacTahoe" 2>/dev/null || true
gtk-update-icon-cache -f "$HOME/.local/share/icons/MacTahoe-dark" 2>/dev/null || true

echo "==> [7/9] Downloading & installing GNOME 50 extensions..."
SHELL_VER="$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)"
python3 - "$SHELL_VER" "$SRC_DIR/extensions" <<'EOF'
import sys, os, urllib.request, json

shell_ver, out_dir = sys.argv[1], sys.argv[2]
uuids = [
    "blur-my-shell@aunetx",
    "rounded-window-corners@fxgn",
    "compiz-alike-magic-lamp-effect@hermes83.github.com",
    "raccoonlauncher@shimafallah.github.io",
]
for uuid in uuids:
    info_url = f"https://extensions.gnome.org/extension-info/?uuid={uuid}&shell_version={shell_ver}"
    req = urllib.request.Request(info_url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read().decode())
    dl_url = "https://extensions.gnome.org" + data["download_url"]
    zip_path = os.path.join(out_dir, f"{uuid}.zip")
    urllib.request.urlretrieve(dl_url, zip_path)
    print(f"    Downloaded {uuid} (v{data.get('version')})")
EOF

for uuid in \
  "blur-my-shell@aunetx" \
  "rounded-window-corners@fxgn" \
  "compiz-alike-magic-lamp-effect@hermes83.github.com" \
  "raccoonlauncher@shimafallah.github.io"; do
  gnome-extensions install --force "$SRC_DIR/extensions/${uuid}.zip"
done

echo "==> [8/9] Applying custom stylesheets (GNOME Shell, Raccoon Launcher, Ptyxis Terminal)..."
SHELL_CSS="$HOME/.themes/MacTahoe-Dark/gnome-shell/gnome-shell.css"
python3 - "$SHELL_CSS" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
marker = "/* CUSTOM_TRANSPARENT_PANEL */"
if marker in s:
    s = s[:s.index(marker)].rstrip() + "\n"
open(p, "w").write(s)
EOF
printf "\n" >> "$SHELL_CSS"
cat "$SCRIPT_DIR/config/gnome-shell-custom.css" >> "$SHELL_CSS"

cp "$SCRIPT_DIR/config/raccoonlauncher.css" \
  "$HOME/.local/share/gnome-shell/extensions/raccoonlauncher@shimafallah.github.io/stylesheet.css"

mkdir -p "$HOME/.local/share/org.gnome.Ptyxis/palettes"
cp "$SCRIPT_DIR/config/MacTahoeDark.palette" \
  "$HOME/.local/share/org.gnome.Ptyxis/palettes/MacTahoeDark.palette"

echo "==> [9/9] Applying all GNOME, Dock, Extension, Terminal, and Shortcut settings..."

# Interface, Theme, Icons, Cursors, Fonts, Wallpapers
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface accent-color 'blue'
gsettings set org.gnome.desktop.interface gtk-theme 'MacTahoe-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'MacTahoe-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'MacTahoe-cursors'
gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11'
gsettings set org.gnome.desktop.interface document-font-name 'SF Pro Text 11'
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'SF Pro Display Bold 11'
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.shell.extensions.user-theme name 'MacTahoe-Dark'

gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.local/share/backgrounds/MacTahoe/MacTahoe-day.jpeg"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/backgrounds/MacTahoe/MacTahoe-night.jpeg"
gsettings set org.gnome.desktop.background picture-options 'zoom'

# macOS Alt+Tab App Switcher & Free Alt+Space for Spotlight
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab', '<Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab', '<Shift><Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>Above_Tab', '<Super>Above_Tab']"

# Floating macOS Bottom Dock (Ubuntu Dock / Dash to Dock)
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 40
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize-or-previews'
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash true
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.0

# Ptyxis Terminal (macOS Dark Glass palette + 0.88 opacity)
if gsettings list-schemas | grep -q "^org\.gnome\.Ptyxis$"; then
  PTYXIS_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")
  gsettings set org.gnome.Ptyxis interface-style 'dark'
  if [ -n "$PTYXIS_UUID" ]; then
    gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PTYXIS_UUID}/" palette 'MacTahoeDark'
    gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PTYXIS_UUID}/" opacity 0.88
  fi
fi

# Blur my Shell (Unified Tahoe Liquid Glass pipeline across Panel, Dock, Quick Settings, Overview, Alt+Tab)
BMS_SCHEMA="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas"
python3 - "$BMS_SCHEMA" <<'EOF'
import sys, subprocess
schema = sys.argv[1]
cur = subprocess.check_output(
    ["gsettings", "--schemadir", schema, "get", "org.gnome.shell.extensions.blur-my-shell", "pipelines"],
    text=True
).strip()
if "'pipeline_tahoe_glass'" not in cur:
    addition = ", 'pipeline_tahoe_glass': {'name': <'Tahoe Liquid Glass'>, 'effects': <[<{'type': <'dual_kawase_blur'>, 'id': <'effect_tahoe_glass_blur'>, 'params': <{'unscaled_radius': <26>, 'brightness': <0.96>}>}>]>}"
    new_val = cur[:-1] + addition + "}"
    subprocess.check_call(
        ["gsettings", "--schemadir", schema, "set", "org.gnome.shell.extensions.blur-my-shell", "pipelines", new_val]
    )
EOF

gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.panel blur true
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.panel static-blur false
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.panel override-background true
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.panel style-panel 0
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.panel override-background-dynamically false
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.panel pipeline 'pipeline_tahoe_glass'

gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur false
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.dash-to-dock override-background false
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.dash-to-dock style-dash-to-dock 0
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.dash-to-dock pipeline 'pipeline_tahoe_glass'
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.dash-to-dock unblur-in-overview true

gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.popup blur true
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.popup blur-quick-settings true
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.popup blur-switchers true
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.popup override-background true
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.popup style-popup 0
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.popup pipeline 'pipeline_tahoe_glass'
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.popup quick-settings-corner-radius 30

gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.overview blur true
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.overview pipeline 'pipeline_tahoe_glass'
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.overview style-components 0
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.overview workspace-corner-radius 24

# Keep per-app Wayland blur off to prevent Electron/Chromium black-region glitches
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.applications blur false
gsettings --schemadir "$BMS_SCHEMA" set org.gnome.shell.extensions.blur-my-shell.applications enable-all false

# Rounded Window Corners Reborn (blacklist Electron apps that glitch on Wayland)
RWC_SCHEMA="$HOME/.local/share/gnome-shell/extensions/rounded-window-corners@fxgn/schemas"
gsettings --schemadir "$RWC_SCHEMA" set org.gnome.shell.extensions.rounded-window-corners-reborn blacklist "['Antigravity', 'antigravity']"

# Raccoon Launcher (Alt+Space Spotlight)
RL_SCHEMA="$HOME/.local/share/gnome-shell/extensions/raccoonlauncher@shimafallah.github.io/schemas"
gsettings --schemadir "$RL_SCHEMA" set org.gnome.shell.extensions.raccoonlauncher toggle-launcher "['<Alt>space']"
gsettings --schemadir "$RL_SCHEMA" set org.gnome.shell.extensions.raccoonlauncher box-color "rgba(18, 18, 24, 0.78)"

# Enable all extensions
gsettings set org.gnome.shell disable-user-extensions false
gsettings set org.gnome.shell enabled-extensions "[
  'user-theme@gnome-shell-extensions.gcampax.github.com',
  'blur-my-shell@aunetx',
  'rounded-window-corners@fxgn',
  'compiz-alike-magic-lamp-effect@hermes83.github.com',
  'raccoonlauncher@shimafallah.github.io',
  'ding@rastersoft.com',
  'ubuntu-dock@ubuntu.com',
  'tiling-assistant@ubuntu.com'
]"

echo ""
echo "========================================================================"
echo "  Setup complete!"
echo "  Log out and log back in once so Wayland loads all GNOME 50 extensions."
echo "  Restart Firefox and Terminal to see their updated macOS themes."
echo "========================================================================"
