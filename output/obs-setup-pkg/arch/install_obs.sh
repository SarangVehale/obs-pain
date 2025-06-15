#!/bin/bash
set -e

echo "🖥️ Detecting Linux distribution..."

# Detect distro and package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot detect distro."
    exit 1
fi

PKG_INSTALL=""
PKG_UPDATE=""
PKG_REMOVE=""

case "$DISTRO" in
    ubuntu|debian)
        PKG_INSTALL="sudo apt-get install -y"
        PKG_UPDATE="sudo apt-get update"
        PKG_REMOVE="sudo apt-get remove --purge -y"
        ;;
    fedora)
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf check-update || true"
        PKG_REMOVE="sudo dnf remove -y"
        ;;
    arch)
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Sy"
        PKG_REMOVE="sudo pacman -Rs --noconfirm"
        ;;
    opensuse*|suse)
        PKG_INSTALL="sudo zypper install -y"
        PKG_UPDATE="sudo zypper refresh"
        PKG_REMOVE="sudo zypper remove -y"
        ;;
    *)
        echo "❌ Unsupported distro: $DISTRO"
        exit 1
        ;;
esac

echo "✅ Detected distro: $DISTRO"

echo "🔍 Detecting GPU..."

GPU_VENDOR="unknown"
if command -v lspci &>/dev/null; then
    gpu_info=$(lspci | grep -Ei 'vga|3d' || true)
    echo "GPU info found: $gpu_info"
    if echo "$gpu_info" | grep -qi 'nvidia'; then
        GPU_VENDOR="nvidia"
    elif echo "$gpu_info" | grep -qi 'amd'; then
        GPU_VENDOR="amd"
    elif echo "$gpu_info" | grep -qi 'intel'; then
        GPU_VENDOR="intel"
    fi
else
    echo "⚠️ lspci not found, skipping GPU detection."
fi

echo "Detected GPU vendor: $GPU_VENDOR"

# Check if OBS is already installed
if command -v obs &>/dev/null; then
    echo "✅ OBS Studio already installed."
    exit 0
fi

echo "⬆️ Updating package repositories..."
$PKG_UPDATE

# Helper function to check if package installed
is_installed() {
    local pkg=$1
    case "$DISTRO" in
        ubuntu|debian)
            dpkg -s "$pkg" &>/dev/null
            ;;
        fedora)
            rpm -q "$pkg" &>/dev/null
            ;;
        arch)
            pacman -Q "$pkg" &>/dev/null
            ;;
        opensuse*|suse)
            rpm -q "$pkg" &>/dev/null
            ;;
    esac
}

# Install missing packages
install_packages() {
    local pkgs=("$@")
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! is_installed "$pkg"; then
            to_install+=("$pkg")
        else
            echo "ℹ️ Package $pkg already installed."
        fi
    done
    if [ ${#to_install[@]} -gt 0 ]; then
        echo "⬇️ Installing packages: ${to_install[*]}"
        $PKG_INSTALL "${to_install[@]}"
    else
        echo "✅ All packages already installed."
    fi
}

# Define common dependencies
COMMON_PKGS=(
    ffmpeg
    v4l2loopback-dkms
    v4l2loopback-utils
)

# OBS package name varies by distro and repo
OBS_PKG="obs-studio"
if [[ "$DISTRO" == "arch" ]]; then
    OBS_PKG="obs-studio"
elif [[ "$DISTRO" == "fedora" ]]; then
    OBS_PKG="obs-studio"
elif [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
    # Add OBS PPA for latest version if Ubuntu
    if [[ "$DISTRO" == "ubuntu" ]]; then
        echo "🔧 Adding OBS PPA repository..."
        if ! grep -q "^deb .*\bobsproject/obs-studio\b" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
            sudo add-apt-repository -y ppa:obsproject/obs-studio
            $PKG_UPDATE
        else
            echo "ℹ️ OBS PPA already added."
        fi
    fi
fi

# Install OBS and dependencies
install_packages "${COMMON_PKGS[@]}"
install_packages "$OBS_PKG"

# Additional GPU driver recommendations (optional, just informative)
case "$GPU_VENDOR" in
    nvidia)
        echo "⚡ Nvidia GPU detected. Make sure you have the proprietary drivers installed:"
        echo "   - Ubuntu/Debian: sudo ubuntu-drivers autoinstall"
        echo "   - Fedora: sudo dnf install akmod-nvidia"
        echo "   - Arch: sudo pacman -S nvidia"
        ;;
    amd)
        echo "⚡ AMD GPU detected. Make sure you have amdgpu drivers installed (usually included)."
        ;;
    intel)
        echo "⚡ Intel GPU detected. Drivers are usually pre-installed."
        ;;
    *)
        echo "⚠️ GPU vendor not recognized or lspci missing."
        ;;
esac

echo "🎉 OBS Studio and dependencies installed successfully!"
exit 0

