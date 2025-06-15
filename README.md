# OBS Easy Installer Project

> **Effortless installation, management, and packaging of OBS Studio on Linux**

---

## Overview

This project provides a **fully automated, interactive, and user-friendly solution** for installing, uninstalling, reinstalling, and packaging OBS Studio on major Linux distributions. It includes:

* Individual install/uninstall/reinstall scripts for OBS with dependency checks
* A packaging script to generate `.deb`, `.tar.gz`, and Arch Linux packages
* A robust **TUI (Text User Interface) launcher script** — `autoinstaller.sh` — that ties everything together
* Hash verification of scripts for security and integrity
* Auto-update mechanism to fetch latest scripts from a remote repo
* Desktop launcher installer for easy GUI access
* Full logging of user actions and installation outputs

---

## Features

* **Cross-distro compatibility:** Supports Ubuntu/Debian, Fedora, Arch, and more
* **Auto dependency checks** and GPU detection for optimized OBS setup
* **Package creation** for distribution or personal use
* **Centralized TUI menu** for ease of use — no need to remember commands or script names
* **Auto chmod +x and auto-update** for all essential scripts
* **Hash verification** to ensure scripts haven’t been tampered with
* **Desktop launcher** integration for native app menu access
* **Comprehensive logs** stored in `~/obs_autoinstaller.log`

---

## Components

| File                | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `install_obs.sh`    | Installs OBS Studio and dependencies                         |
| `uninstall_obs.sh`  | Removes OBS Studio and cleans dependencies                   |
| `reinstall_obs.sh`  | Backs up config and reinstalls OBS                           |
| `package_all.sh`    | Creates `.deb`, `.tar.gz`, and Arch Linux packages           |
| `obs-setup.sh`      | Verifies hashes of scripts for integrity                     |
| `obs-setup.desktop` | Desktop entry for launching OBS setup GUI                    |
| `autoinstaller.sh`  | Central TUI launcher script that orchestrates all operations |

---

## Getting Started

### Prerequisites

* A major Linux distro (Ubuntu, Debian, Fedora, Arch, etc.)
* `curl` or `wget` installed for script auto-update
* Internet connection to download dependencies and scripts

### Installation

1. Clone or download this repo or the scripts into a single folder

2. Make `autoinstaller.sh` executable:

   ```bash
   chmod +x autoinstaller.sh
   ```

3. Run the autoinstaller:

   ```bash
   ./autoinstaller.sh
   ```

4. Use the interactive menu to install, uninstall, reinstall, package, or install the desktop launcher

---

## Usage

Upon running `autoinstaller.sh`, you get a clean TUI menu:

```
================== OBS AutoInstaller Menu ====================
Please select an option:
  1) Install OBS Studio
  2) Uninstall OBS Studio
  3) Reinstall OBS Studio (with backup)
  4) Package all (build .deb, tar.gz, etc.)
  5) Install desktop launcher
  6) Exit
==============================================================
```

* **Install** will setup OBS Studio with dependencies for your detected distro
* **Uninstall** will cleanly remove OBS and dependencies
* **Reinstall** backs up configs and reinstalls OBS
* **Package all** builds installable packages for easy distribution
* **Install desktop launcher** adds an app menu shortcut for the OBS setup GUI
* **Exit** closes the program

---

## Auto-Update & Verification

* Before each action, the autoinstaller checks for updated versions of all scripts from the remote repo URL (configurable in `autoinstaller.sh`)
* It downloads and replaces outdated scripts, ensuring you always run the latest code
* Scripts are verified via `obs-setup.sh` for hash integrity before execution
* All outputs and actions are logged in `~/obs_autoinstaller.log` for easy troubleshooting

---

## Developer Guide

### Adding/Updating Scripts

1. Add your new or updated scripts to your remote repo
2. Update `REPO_BASE_URL` in `autoinstaller.sh` to point to your repo's raw files
3. The autoinstaller will auto-download new scripts on next run

### Packaging

* Modify `package_all.sh` to customize package contents or formats
* Use Debian control files, Arch PKGBUILD, or tarball structures as needed
* The autoinstaller TUI lets users build packages without manual commands

### Desktop Entry

* Update `obs-setup.desktop` to customize icon, name, or exec path
* Desktop launcher installs to `~/.local/share/applications` for per-user access

---

## Logging

* All actions and output are appended to `~/obs_autoinstaller.log`
* Check this file if any issues arise during installation or packaging

---

## Contribution

We welcome contributions! Here’s how you can help:

* Fork the repo and submit pull requests
* Improve or add support for more distros
* Enhance the TUI or build a GUI wrapper
* Add tests for script verification and package creation
* Report bugs or request features via issues

---

## License

This project is licensed under the MIT License — see the LICENSE file for details.

---

## Contact

For questions or support, reach out via GitHub issues or:

* Your Name / Maintainer
* Email: [sarangvehale2@gmail.com](mailto:sarangvehale2@gmail.com)
* GitHub: [https://github.com/SarangVehale/obs-pain.git](https://github.com/SarangVehale/obs-pain.git)

---

### Thank you for making OBS setup on Linux effortless!

---
