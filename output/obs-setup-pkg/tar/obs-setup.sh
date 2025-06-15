#!/bin/bash
set -e

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"

declare -A SCRIPT_HASHES=(
    ["install_obs.sh"]="f8bd801027fb4ba5a873da8773bd364232258e5f20774f14e7e2d098553bab95"
    ["obs-setup.desktop"]="685264e2af21774c3217bbe1da891361ec19203fac11b5d0512237b932571f9c"
    ["uninstall_obs.sh"]="98bc01d2192437d352aeb7387fd264bfbe3abc7e6db26fd48394b0f39986d226"
    ["reinstall_obs.sh"]="1cdc978d9e5c87ccee92b00edf7f70a067a5a69c9d49241de33ddede49a5a6d1"
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
