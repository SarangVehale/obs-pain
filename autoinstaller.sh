#!/bin/bash
set -euo pipefail

# === Config ===
REPO_BASE_URL="https://github.com/SarangVehale/obs-pain" # <-- change this to your real repo URL
SCRIPTS=(install_obs.sh uninstall_obs.sh reinstall_obs.sh package_all.sh obs-setup.sh)
DESKTOP_ENTRY="obs-setup.desktop"
LOGFILE="$HOME/obs_autoinstaller.log"

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# === Logging ===
log() {
  local msg="$1"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') : $msg" | tee -a "$LOGFILE"
}

pause() {
  read -rp "Press Enter to continue..."
}

# === Ensure scripts exist and are executable, else download ===
check_and_update_scripts() {
  log "Checking scripts and updating from repo if needed..."
  for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
      log "Script $script missing. Downloading..."
      curl -fsSL "$REPO_BASE_URL/$script" -o "$script" || { log "Failed to download $script"; exit 1; }
      chmod +x "$script"
      log "Downloaded and set executable: $script"
    else
      # Optionally update if remote version differs (simple re-download)
      log "Checking for updates to $script..."
      curl -fsSL "$REPO_BASE_URL/$script" -o "${script}.new" || { log "Failed to fetch $script update"; exit 1; }
      if ! cmp -s "$script" "${script}.new"; then
        log "Update found for $script, applying..."
        mv "${script}.new" "$script"
        chmod +x "$script"
      else
        log "No update for $script"
        rm -f "${script}.new"
      fi
    fi
  done
}

# === Verify hashes by calling obs-setup.sh ===
verify_scripts() {
  log "Verifying scripts using obs-setup.sh..."
  ./obs-setup.sh verify || { log "Verification failed"; exit 1; }
  log "Verification succeeded"
}

detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    log "Detected Linux distro: $DISTRO"
  else
    log "Cannot detect Linux distro, exiting."
    echo -e "${RED}Cannot detect Linux distro.${NC}"
    exit 1
  fi
}

install_desktop_launcher() {
  if [ ! -f "$DESKTOP_ENTRY" ]; then
    log "Desktop entry '$DESKTOP_ENTRY' not found, skipping."
    echo -e "${RED}Desktop entry not found. Skipping desktop launcher installation.${NC}"
    return
  fi
  local target_dir="$HOME/.local/share/applications"
  mkdir -p "$target_dir"
  cp "$DESKTOP_ENTRY" "$target_dir/"
  log "Installed desktop launcher to $target_dir"
  echo -e "${GREEN}Desktop launcher installed to $target_dir${NC}"
}

show_menu() {
  clear
  echo -e "${CYAN}================== OBS AutoInstaller Menu ===================="
  echo "Please select an option:"
  echo "  1) Install OBS Studio"
  echo "  2) Uninstall OBS Studio"
  echo "  3) Reinstall OBS Studio (with backup)"
  echo "  4) Package all (build .deb, tar.gz, etc.)"
  echo "  5) Install desktop launcher"
  echo "  6) Exit"
  echo -e "==============================================================${NC}"
}

main() {
  log "Starting autoinstaller execution."

  detect_distro
  check_and_update_scripts
  verify_scripts

  while true; do
    show_menu
    read -rp "Enter choice [1-6]: " choice
    case $choice in
      1)
        log "User chose to install OBS."
        echo -e "${YELLOW}Installing OBS Studio...${NC}"
        ./install_obs.sh 2>&1 | tee -a "$LOGFILE"
        install_desktop_launcher
        pause
        ;;
      2)
        log "User chose to uninstall OBS."
        echo -e "${YELLOW}Uninstalling OBS Studio...${NC}"
        ./uninstall_obs.sh 2>&1 | tee -a "$LOGFILE"
        pause
        ;;
      3)
        log "User chose to reinstall OBS."
        echo -e "${YELLOW}Reinstalling OBS Studio...${NC}"
        ./reinstall_obs.sh 2>&1 | tee -a "$LOGFILE"
        install_desktop_launcher
        pause
        ;;
      4)
        log "User chose to package all."
        echo -e "${YELLOW}Packaging all...${NC}"
        ./package_all.sh 2>&1 | tee -a "$LOGFILE"
        pause
        ;;
      5)
        log "User chose to install desktop launcher."
        install_desktop_launcher
        pause
        ;;
      6)
        log "User exited autoinstaller."
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid choice, please try again.${NC}"
        ;;
    esac
  done
}

main "$@"

