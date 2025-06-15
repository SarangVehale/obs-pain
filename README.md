# OBS Setup Scripts

A set of cross-distro Bash scripts to **install**, **uninstall**, and **reinstall** OBS Studio along with its dependencies and virtual camera support, with GPU detection and intelligent package management.

---

## Features

* Supports major Linux distributions:

  * Debian / Ubuntu (APT)
  * Fedora (DNF)
  * Arch Linux (Pacman)
  * OpenSUSE (Zypper)
* Detects GPU vendor (NVIDIA, AMD, Intel) and prints driver recommendations
* Installs only missing packages to save time and bandwidth
* Backs up and optionally restores OBS configuration on reinstall
* Includes virtual camera modules (`v4l2loopback`)
* Provides clear console output and status messages

---

## Files

| Script              | Description                                                                 |
| ------------------- | --------------------------------------------------------------------------- |
| `install_obs.sh`    | Installs OBS Studio and dependencies                                        |
| `uninstall_obs.sh`  | Removes OBS Studio and related packages                                     |
| `reinstall_obs.sh`  | Uninstalls and reinstalls OBS Studio with config backup and restore options |
| `obs-setup.desktop` | Desktop entry file for easy GUI launcher integration (optional)             |

---

## Usage

1. **Make scripts executable:**

   ```bash
   chmod +x install_obs.sh uninstall_obs.sh reinstall_obs.sh
   ```

2. **Run the installer:**

   ```bash
   ./install_obs.sh
   ```

3. **Uninstall OBS:**

   ```bash
   ./uninstall_obs.sh
   ```

4. **Reinstall OBS (backs up config and prompts to restore):**

   ```bash
   ./reinstall_obs.sh
   ```

---

## Packaging

These scripts can be bundled into `.deb`, `.tar.gz`, and `.pkg.tar.zst` packages for easy distribution and installation. See the packaging scripts for details.

---

## Contributing

Contributions, suggestions, and bug reports are welcome! Here's how you can help:

### How to Contribute

1. **Fork the repository** and clone it locally.

2. **Create a new branch** for your feature or fix:

   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make your changes**, ensuring the scripts remain compatible across supported distros.

4. **Test your changes** thoroughly on supported distros if possible.

5. **Submit a pull request** with a clear description of your changes.

### Coding Style & Guidelines

* Use `bash` syntax and best practices.
* Scripts should handle errors gracefully.
* Provide clear user-friendly output.
* Maintain idempotency (running scripts multiple times should not break anything).
* Document any new dependencies or required steps.

### Reporting Issues

* Use GitHub Issues to report bugs or request features.
* Provide distro info, script version, and detailed steps to reproduce.

---

## License

MIT License — see `LICENSE` file for details.

---

## Acknowledgements

Thanks to the open-source community and OBS Studio team for providing great software and tools!

---

