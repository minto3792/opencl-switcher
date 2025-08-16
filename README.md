
# OpenCL Switcher GUI + DaVinci Resolve Fix

*A GPLv3 community tool for managing NVIDIA/AMD OpenCL drivers on Linux hybrid systems*

## 📌 Overview

This script provides a simple **Zenity-based GUI** to manage OpenCL vendor configurations for systems that have both NVIDIA and AMD GPUs (or Mesa drivers).

It allows you to:

* Switch between **NVIDIA CUDA**, **AMD OpenCL/Mesa**, or **Both**.
* Enable or disable the **Nouveau driver** (open-source NVIDIA driver).
* View basic **system GPU and driver info**.
* Apply a **DaVinci Resolve library fix** (`davinci_fix`) for compatibility.

⚠️ **Disclaimer:**
This tool modifies system driver configurations and may affect system stability. Please review the code before running. Use at your own risk.

---

## 📜 License & Legal

* Licensed under **GNU GPL v3.0 or later**.
* You are free to use, modify, and redistribute this project under GPL terms.
* **Trademarks:** NVIDIA, AMD, and DaVinci Resolve are trademarks of their respective owners. This project is **not affiliated with or endorsed by** them.

---

## 🛠️ Dependencies

Ensure the following are installed:

* `zenity` → for GUI dialogs.
* `update-initramfs` → (Debian/Ubuntu) to apply Nouveau blacklist/whitelist.

  * On Fedora/Arch, use `dracut` or `mkinitcpio` instead.
* `lspci`, `modinfo` → for system info display.
* `sudo` or `pkexec` → for privilege escalation.

On Debian/Ubuntu:

```bash
sudo apt install zenity pciutils kmod policykit-1
```

---

## 📂 Installation

1. Clone or download this repository.
2. Save the main script as:

   ```bash
   opencl-switcher.sh
   ```
3. Make it executable:

   ```bash
   chmod +x opencl-switcher.sh
   ```

Optional: Add it to your `$PATH` for easy access:

```bash
sudo mv opencl-switcher.sh /usr/local/bin/opencl-switcher
```

---

## 🚀 Usage

Run from a desktop session:

```bash
./opencl-switcher.sh
```

If not root, the script will relaunch using `pkexec` or `sudo`.

### GUI Options:

* **OPENCL\_CUDA** → Enable NVIDIA CUDA only (e.g., for DaVinci Resolve).
* **OPENCL\_AMD** → Enable AMD/Mesa only (e.g., for gaming).
* **OPENCL\_BOTH** → Enable both CUDA and AMD OpenCL.
* **NOUVEAU\_BLACKLIST** → Disable Nouveau (required for proprietary NVIDIA).
* **NOUVEAU\_WHITELIST** → Re-enable Nouveau (remove script-created block).
* **INFO** → Show GPU and driver versions.
* **REBOOT** → Restart system to apply changes.
* **EXIT** → Close the application.

---

## 🎬 DaVinci Resolve Fix (`davinci_fix`)

DaVinci Resolve sometimes ships with incompatible **GLib/GObject** libraries. This fix moves Resolve’s bundled copies out of the way so the system libraries are used.

To apply manually:

```bash
sudo ./opencl-switcher.sh --davinci-fix
```

What it does:

* Navigates to `/opt/resolve/libs`
* Creates an `oldlibs/` directory
* Moves `libglib*`, `libgio*`, `libgmodule*`, `libgobject*` into `oldlibs/`

---

## 🧑‍💻 Development Notes

* Logs are written to: `/tmp/opencl-switcher-gui.log`
* Preferences are saved to: `~/.config/opencl-switcher.conf`
* All script-created files contain a **marker** (`# Created by OpenCL Switcher`) for safe cleanup.

---

## ❗ Known Risks & Fixes

| Risk                                         | Fix / Mitigation                                                                             |
| -------------------------------------------- | -------------------------------------------------------------------------------------------- |
| System fails to boot due to Nouveau changes  | Boot with `nomodeset` kernel param, remove `/etc/modprobe.d/blacklist-nouveau.conf` manually |
| Wrong drivers enabled                        | Use **INFO** → check config, then re-enable correct mode                                     |
| DaVinci Resolve crashes due to GLib mismatch | Run `--davinci-fix` to move bundled libraries                                                |
| Distro without `update-initramfs`            | Manually rebuild initramfs using `dracut`/`mkinitcpio`                                       |

---

## 🤝 Contributions

* Contributions are welcome under GPLv3+.
* Please open issues or submit pull requests.

---

## 📧 Support

This is a **community tool**. No official vendor support. For issues:

* Check `/tmp/opencl-switcher-gui.log`.
* Open a GitHub issue with details.

