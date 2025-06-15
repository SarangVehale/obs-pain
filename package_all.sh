#!/bin/bash
set -e

PKGNAME="obs-setup"
VERSION="1.0"
ARCH="all"
MAINTAINER="Your Name <you@example.com>"
DESCRIPTION="Custom installer/uninstaller/reinstaller for OBS Studio with GPU & virtual camera support."

OUTPUT_DIR="./output"
PKG_DIR="${OUTPUT_DIR}/${PKGNAME}-pkg"
DEB_DIR="${PKG_DIR}/deb"
ARCH_DIR="${PKG_DIR}/arch"
TAR_DIR="${PKG_DIR}/tar"

SCRIPTS=("install_obs.sh" "uninstall_obs.sh" "reinstall_obs.sh")
DESKTOP_FILE="obs-setup.desktop"
LAUNCHER="obs-setup.sh"

# Check dependencies
for cmd in dpkg-deb tar dialog sha256sum; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ $cmd is required but not installed."
        exit 1
    fi
done

if ! command -v makepkg &>/dev/null; then
    echo "⚠️ makepkg not found. Arch package will NOT be built."
    BUILD_ARCH=0
else
    BUILD_ARCH=1
fi

echo "📁 Cleaning and creating output directories..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$DEB_DIR/usr/local/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$ARCH_DIR"
mkdir -p "$TAR_DIR"

echo "📦 Copying your scripts and desktop file..."
for script in "${SCRIPTS[@]}" "$DESKTOP_FILE"; do
    if [[ ! -f "$script" ]]; then
        echo "❌ File $script not found. Please add it before running this script."
        exit 1
    fi
    cp "$script" "$DEB_DIR/usr/local/bin/"
    cp "$script" "$ARCH_DIR/"
    cp "$script" "$TAR_DIR/"
done

chmod +x "$DEB_DIR/usr/local/bin/"*.sh
chmod +x "$ARCH_DIR/"*.sh
chmod +x "$TAR_DIR/"*.sh

# Generate SHA256 hashes for your scripts and desktop file
declare -A SCRIPT_HASHES
for file in "${SCRIPTS[@]}" "$DESKTOP_FILE"; do
    hash=$(sha256sum "$file" | awk '{print $1}')
    SCRIPT_HASHES[$file]=$hash
done

# Create the launcher script with embedded hashes
echo "🖋 Creating launcher script ($LAUNCHER) with embedded hashes..."

cat > "$LAUNCHER" <<'EOF'
#!/bin/bash
set -e

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"

declare -A SCRIPT_HASHES=(
EOF

for file in "${!SCRIPT_HASHES[@]}"; do
    echo "    [\"$file\"]=\"${SCRIPT_HASHES[$file]}\"" >> "$LAUNCHER"
done

cat >> "$LAUNCHER" <<'EOF'
)

verify_script() {
    local script="$1"
    local expected_hash="${SCRIPT_HASHES[$script]}"
    local file_path="${SCRIPTS_DIR}/$script"

    if [ ! -f "$file_path" ]; then
        dialog --msgbox "❌ $script not found!" 6 40
        return 1
    fi

    local actual_hash
    actual_hash=$(sha256sum "$file_path" | awk '{print $1}')

    if [ "$actual_hash" != "$expected_hash" ]; then
        dialog --msgbox "⚠️ Hash mismatch for $script!\nExpected:\n$expected_hash\nActual:\n$actual_hash" 10 60
        return 1
    fi
    return 0
}

run_script_verified() {
    local script="$1"
    verify_script "$script" || return 1
    bash "$SCRIPTS_DIR/$script"
}

backup_config() {
    if [ -d "$HOME/.config/obs-studio" ]; then
        local backup_dir="$HOME/obs-config-backup-$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        cp -r "$HOME/.config/obs-studio" "$backup_dir"
    fi
}

restore_config() {
    dialog --clear --inputbox "Enter path to backup directory to restore config (leave blank to skip):" 8 60 "" 2> /tmp/obsbackupdir
    local backup_dir
    backup_dir=$(< /tmp/obsbackupdir)
    rm /tmp/obsbackupdir
    if [[ -n "$backup_dir" && -d "$backup_dir/obs-studio" ]]; then
        cp -r "$backup_dir/obs-studio" "$HOME/.config/"
        dialog --msgbox "OBS config restored from $backup_dir" 6 50
    else
        dialog --msgbox "No valid backup provided. Skipping restore." 6 50
    fi
}

show_menu() {
    cmd=(dialog --clear --backtitle "OBS Studio Setup" --title "Setup Menu" \
        --menu "Choose action:" 15 60 5)
    options=(
        1 "Install OBS Studio"
        2 "Uninstall OBS Studio"
        3 "Reinstall OBS Studio"
        4 "Quit"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    echo "$choice"
}

ask_desktop_entry() {
    dialog --clear --yesno "Install desktop launcher (obs-setup.desktop)?" 7 60
    return $?
}

clear
while true; do
    choice=$(show_menu)
    case $choice in
        1)
            backup_config
            run_script_verified "install_obs.sh" || { dialog --msgbox "Installation aborted due to script verification failure." 6 60; continue; }
            if ask_desktop_entry; then
                cp "$SCRIPTS_DIR/obs-setup.desktop" "$HOME/.local/share/applications/"
                dialog --msgbox "Desktop launcher installed." 6 40
            fi
            dialog --msgbox "OBS Studio installation complete." 6 40
            ;;
        2)
            run_script_verified "uninstall_obs.sh" || { dialog --msgbox "Uninstallation aborted due to script verification failure." 6 60; continue; }
            dialog --msgbox "OBS Studio uninstalled." 6 40
            ;;
        3)
            backup_config
            run_script_verified "reinstall_obs.sh" || { dialog --msgbox "Reinstallation aborted due to script verification failure." 6 60; continue; }
            if ask_desktop_entry; then
                cp "$SCRIPTS_DIR/obs-setup.desktop" "$HOME/.local/share/applications/"
                dialog --msgbox "Desktop launcher installed." 6 40
            fi
            dialog --msgbox "OBS Studio reinstallation complete." 6 50
            restore_config
            ;;
        4)
            clear
            exit 0
            ;;
        *)
            clear
            exit 0
            ;;
    esac
done
EOF

chmod +x "$LAUNCHER"

# Copy launcher to package dirs
cp "$LAUNCHER" "$DEB_DIR/usr/local/bin/"
cp "$LAUNCHER" "$ARCH_DIR/"
cp "$LAUNCHER" "$TAR_DIR/"

chmod +x "$DEB_DIR/usr/local/bin/$LAUNCHER"
chmod +x "$ARCH_DIR/$LAUNCHER"
chmod +x "$TAR_DIR/$LAUNCHER"

# Create Debian control file
mkdir -p "$DEB_DIR/DEBIAN"
cat > "$DEB_DIR/DEBIAN/control" <<EOF
Package: $PKGNAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: $MAINTAINER
Description: $DESCRIPTION
EOF

echo "📦 Creating Debian package..."
sudo chown -R root:root "$DEB_DIR"
dpkg-deb --build --root-owner-group "$DEB_DIR" "${OUTPUT_DIR}/${PKGNAME}_${VERSION}.deb"

echo "📦 Creating tar.gz archive..."
cd "$TAR_DIR"
tar -czvf "../../${PKGNAME}-${VERSION}.tar.gz" ./*
cd - > /dev/null

if [ "$BUILD_ARCH" -eq 1 ]; then
    echo "📦 Creating Arch package..."
    cat > "${ARCH_DIR}/PKGBUILD" <<'EOF'
pkgname=obs-setup
pkgver=1.0
pkgrel=1
pkgdesc="Custom installer/uninstaller/reinstaller for OBS Studio with GPU & virtual camera support"
arch=('any')
url="https://github.com"
license=('MIT')
depends=('bash' 'dialog')
source=()
package() {
    install -Dm755 install_obs.sh "$pkgdir/usr/local/bin/install_obs.sh"
    install -Dm755 uninstall_obs.sh "$pkgdir/usr/local/bin/uninstall_obs.sh"
    install -Dm755 reinstall_obs.sh "$pkgdir/usr/local/bin/reinstall_obs.sh"
    install -Dm755 obs-setup.sh "$pkgdir/usr/local/bin/obs-setup.sh"
    install -Dm644 obs-setup.desktop "$pkgdir/usr/share/applications/obs-setup.desktop"
}
EOF
    cd "$ARCH_DIR"
    makepkg --packagetype pkg.tar.zst --noconfirm
    mv *.pkg.tar.zst "../${PKGNAME}-1.0-arch.pkg.tar.zst"
    cd - > /dev/null
else
    echo "Skipping Arch package creation."
fi

# Generate SHA256 sums for packages
echo "📊 Generating SHA256 checksums for packages..."
cd "$OUTPUT_DIR"
sha256sum "${PKGNAME}_${VERSION}.deb" > SHA256SUMS
sha256sum "${PKGNAME}-${VERSION}.tar.gz" >> SHA256SUMS

if [ -f "${PKGNAME}-1.0-arch.pkg.tar.zst" ]; then
    sha256sum "${PKGNAME}-1.0-arch.pkg.tar.zst" >> SHA256SUMS
fi
cd - > /dev/null

echo "✅ Packaging complete! Find your packages in $OUTPUT_DIR"

