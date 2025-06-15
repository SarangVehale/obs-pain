#!/bin/bash
set -e

echo "🖥️ Detecting Linux distribution..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot detect distro."
    exit 1
fi

PKG_REMOVE=""
PKG_AUTOREMOVE=""

case "$DISTRO" in
    ubuntu|debian)
        PKG_REMOVE="sudo apt-get remove --purge -y"
        PKG_AUTOREMOVE="sudo apt-get autoremove -y"
        ;;
    fedora)
        PKG_REMOVE="sudo dnf remove -y"
        PKG_AUTOREMOVE="sudo dnf autoremove -y"
        ;;
    arch)
        PKG_REMOVE="sudo pacman -Rs --noconfirm"
        PKG_AUTOREMOVE=""  # pacman removes deps automatically
        ;;
    opensuse*|suse)
        PKG_REMOVE="sudo zypper remove -y"
        PKG_AUTOREMOVE=""
        ;;
    *)
        echo "❌ Unsupported distro: $DISTRO"
        exit 1
        ;;
esac

echo "✅ Detected distro: $DISTRO"

# Check if OBS is installed
if ! command -v obs &>/dev/null; then
    echo "ℹ️ OBS Studio not installed."
    exit 0
fi

# List of packages to remove
REMOVE_PKGS=(
    obs-studio
    v4l2loopback-dkms
    v4l2loopback-utils
    ffmpeg
)

echo "🗑️ Removing OBS Studio and dependencies..."

for pkg in "${REMOVE_PKGS[@]}"; do
    case "$DISTRO" in
        ubuntu|debian)
            dpkg -s "$pkg" &>/dev/null && $PKG_REMOVE "$pkg" || echo "ℹ️ Package $pkg not installed."
            ;;
        fedora)
            rpm -q "$pkg" &>/dev/null && $PKG_REMOVE "$pkg" || echo "ℹ️ Package $pkg not installed."
            ;;
        arch)
            pacman -Q "$pkg" &>/dev/null && $PKG_REMOVE "$pkg" || echo "ℹ️ Package $pkg not installed."
            ;;
        opensuse*|suse)
            rpm -q "$pkg" &>/dev/null && $PKG_REMOVE "$pkg" || echo "ℹ️ Package $pkg not installed."
            ;;
    esac
done

# Clean up unnecessary dependencies if supported
if [ -n "$PKG_AUTOREMOVE" ]; then
    echo "🧹 Running autoremove..."
    $PKG_AUTOREMOVE
fi

echo "✅ OBS Studio and related packages removed."

exit 0

