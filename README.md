# Ubuntu 26.04 (GNOME 50) — macOS 26 Tahoe Dark Glass Setup

A complete, one-command reproducible setup to transform **Ubuntu 26.04 LTS (GNOME Shell 50 / Wayland)** into a unified **macOS 26 Tahoe Dark Glass** desktop.

---

## Quick Install on a New Ubuntu 26.04 Device

```bash
git clone https://github.com/farisemad3030-sudo/ubuntu-macos-tahoe-setup.git
cd ubuntu-macos-tahoe-setup
chmod +x install.sh restore.sh
./install.sh
```

Then **log out and log back in once** so Wayland loads all newly installed GNOME Shell extensions, and reopen Firefox & Terminal.

> To revert to your previous Ubuntu desktop anytime, run `./restore.sh`.

---

## What Gets Installed

### 1. APT Packages
| Package | Purpose |
| --- | --- |
| `git`, `curl` | Cloning themes, fonts, and downloading GNOME 50 extensions |
| `sassc`, `libglib2.0-dev-bin`, `libxml2-utils` | Compiling `MacTahoe-gtk-theme` SCSS & GResources |
| `gnome-tweaks` | GUI to switch GTK/Shell themes, icons, cursors, and fonts |
| `gnome-shell-extensions` | Provides **User Themes** extension (GNOME 50) |
| `gnome-shell-extension-manager` | GUI to manage and tune all GNOME extensions |

### 2. GitHub Theme & Asset Repositories
| Component | Repository | What's Installed |
| --- | --- | --- |
| **GTK3 / GTK4 / Shell / Firefox Theme** | [vinceliuice/MacTahoe-gtk-theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) | Both `MacTahoe-Dark` & `MacTahoe-Light` Liquid Glass blur (`-b`), Dark libadwaita (`-l`), Apple top-bar icon (`--shell -i apple`), Day & Night wallpapers, and macOS Safari Firefox theme (`./tweaks.sh -f`) |
| **Icons & Cursors** | [vinceliuice/MacTahoe-icon-theme](https://github.com/vinceliuice/MacTahoe-icon-theme) | `MacTahoe` / `MacTahoe-dark` / `MacTahoe-light` icons + `MacTahoe-cursors` |
| **System Fonts** | [sahibjotsaggu/San-Francisco-Pro-Fonts](https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts) | Apple **SF Pro Text** (`11pt`) & **SF Pro Display Bold** (`11pt`) |

### 3. GNOME Shell 50 Extensions
| Extension | UUID | Role |
| --- | --- | --- |
| **User Themes** | `user-theme@gnome-shell-extensions.gcampax.github.com` | Loads `MacTahoe-Dark` Shell theme |
| **Blur my Shell** | `blur-my-shell@aunetx` | Unified frosted glass blur (`Tahoe Liquid Glass` pipeline) on Top Bar, Dock, Quick Settings, Overview, and Alt+Tab |
| **Rounded Window Corners Reborn** | `rounded-window-corners@fxgn` | Smooth rounded corners on app windows |
| **Compiz alike Magic Lamp Effect** | `compiz-alike-magic-lamp-effect@hermes83.github.com` | macOS Genie minimize animation |
| **Raccoon Launcher** | `raccoonlauncher@shimafallah.github.io` | Standalone macOS Spotlight search bar bound to `Alt+Space` |

---

## Specific Settings & Customizations Applied

### Appearance, Fonts & Window Controls
- **Color Scheme & Accent:** `prefer-dark` + `accent-color = 'blue'`
- **Themes:** GTK `MacTahoe-Dark`, Shell `MacTahoe-Dark`, Icons `MacTahoe-dark`, Cursors `MacTahoe-cursors`
- **Fonts:** UI/Document `SF Pro Text 11`, Window Titles `SF Pro Display Bold 11`
- **Wallpapers:** `MacTahoe-day.jpeg` (Light) / `MacTahoe-night.jpeg` (Dark) — auto-switches with system mode
- **Window Buttons:** Right side in Windows order (`:minimize,maximize,close`), patched in GTK3/GTK4 CSS so unfocused buttons stay visibly colored instead of blank grey circles
- **Snap App Icons Fix:** User-level `.desktop` overrides in `~/.local/share/applications/` for `firefox`, `thunderbird`, `snap-store`, `desktop-security-center`, and `firmware-updater` so Snap apps use MacTahoe macOS icons

### Unified Tahoe Dark Glass Shell (`config/gnome-shell-custom.css`)
- **Top Bar:** Slim `28px` transparent dark glass bar (`rgba(18, 18, 24, 0.18)`), white **Apple logo** on top-left (replacing GNOME workspace dots), weekday + date + battery `%` enabled, dynamic `Tahoe Liquid Glass` blur
- **Bottom Dock:** Floating dark glass capsule (`border-radius: 22px`, `rgba(18, 18, 22, 0.24)`, thin white glass border `rgba(255, 255, 255, 0.24)`), `40px` icons, auto/intellihide, Trash enabled, mounted drives hidden, click-to-minimize (`minimize-or-previews`)
- **Quick Settings:** Medium balanced size (`30px` outer corners), translucent glass (`rgba(18, 18, 24, 0.22)`), circular pill buttons (`border-radius: 9999px`) with white circle + macOS Blue icon badges when active, slim borderless sliders
- **Overview & Launchpad:** Frosted wallpaper (`Tahoe Liquid Glass` pipeline), glass pill search bar, rounded workspace cards & app grid folders
- **Alt+Tab Switcher:** Frosted dark glass capsule matching the dock & Quick Settings

### Shortcuts & Productivity
- **`Alt+Tab` / `Super+Tab`:** macOS-style application switcher (`switch-applications`)
- **`Alt+\`` (above Tab):** Switch between windows of the same application (`switch-group`)
- **`Alt+Space`:** macOS Spotlight search via **Raccoon Launcher** (`config/raccoonlauncher.css`, unbound from Ubuntu's `activate-window-menu`)

### Terminal & Browser
- **Ptyxis Terminal:** Custom dark/light macOS palette (`config/MacTahoeDark.palette`, `#141418` background) + `0.88` translucent opacity
- **Firefox:** `MacTahoe` Safari-style theme installed into Snap Firefox profile with `toolkit.legacyUserProfileCustomizations.stylesheets = true`

### Stability Tweaks for Wayland / Electron
- Disabled **Blur my Shell → Applications** per-window blur (`blur = false`) and blacklisted `Antigravity` in **Rounded Window Corners Reborn** to avoid Wayland Electron/Chromium black-region rendering glitches.

---

## Repository Structure

```text
ubuntu-macos-tahoe-setup/
├── install.sh                    # Full automated installer for a fresh Ubuntu 26.04 machine
├── restore.sh                    # Restores backed-up GNOME dconf settings
├── README.md                     # Complete documentation
└── config/
    ├── gnome-shell-custom.css    # Top Bar, Dock, Quick Settings, Alt+Tab, Overview CSS
    ├── raccoonlauncher.css       # Alt+Space Spotlight bar CSS
    ├── MacTahoeDark.palette      # Ptyxis Terminal macOS Dark/Light color palette
    └── settings-snapshot.txt     # Exact snapshot of all live gsettings values
```

---

## Live-Reload Shell CSS After Manual Edits

```bash
gsettings set org.gnome.shell.extensions.user-theme name '' && gsettings set org.gnome.shell.extensions.user-theme name 'MacTahoe-Dark'
```

## Push This Repo to Your GitHub Account

1. Create a new empty repository on GitHub (e.g. `ubuntu-macos-tahoe-setup`).
2. Run inside this folder:
   ```bash
   git remote add origin https://github.com/farisemad3030-sudo/ubuntu-macos-tahoe-setup.git
   git branch -M main
   git push -u origin main
   ```
