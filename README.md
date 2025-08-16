# OpenCL Switcher GUI v1.4 (GPL-3.0)

**A Linux GUI utility for switching between NVIDIA CUDA, AMD OpenCL, and Mesa drivers, with optional Nouveau driver blacklist/whitelist controls.**

> **Note:** This project is community-provided and **unaffiliated** with NVIDIA, AMD, or any other vendor.

---

## Features
- Enable **NVIDIA CUDA only** (recommended for DaVinci Resolve workflows)
- Enable **AMD/Mesa only** (recommended for gaming)
- Enable **both NVIDIA and AMD/Mesa**
- Blacklist Nouveau driver (for proprietary NVIDIA compatibility)
- Whitelist Nouveau driver (revert script-created blacklist)
- Show GPU and driver version info
- Safe root privilege handling (`pkexec` or `sudo`)
- Transaction-safe file moves to avoid breaking ICD configuration

---

## Requirements
- **Zenity** (for GUI dialogs)
- **update-initramfs** (Debian/Ubuntu; adapt for your distro if using `dracut` or `mkinitcpio`)
- `pkexec` (optional; for graphical elevation)
- `sudo` (fallback privilege escalation)
- `lspci`, `modinfo` (optional; for INFO dialog)

---

## Installation
```bash
git clone https://github.com/YOUR_USERNAME/opencl-switcher.git
cd opencl-switcher
chmod +x opencl-switcher.sh
