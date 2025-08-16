# OpenCL Switcher GUI + DaVinci Resolve Fix

*Specialized tool for AMD-primary + NVIDIA-secondary hybrid GPU systems*

## 📌 Overview

This script provides a **Zenity-based GUI** to manage OpenCL configurations on hybrid GPU systems with **AMD as the primary GPU** and **NVIDIA as the secondary GPU**. It's ideal for content creators and professionals who need to switch between GPU configurations for different workloads.

![Main Menu Screenshot](https://github.com/minto3792/opencl-switcher/blob/f7b28e8b491b6623e08a858ab7c3c8505ca09b34/opencswitchgui.jpg)

## 🎯 Key Features

- **Hybrid GPU Management**:
  - Specifically designed for AMD-primary + NVIDIA-secondary setups
  - Switch between NVIDIA-only, AMD-only, or both GPUs
- **DaVinci Resolve Fix**:
  - Resolves library conflicts in hybrid setups
- **Nouveau Control**:
  - Blacklist/whitelist open-source NVIDIA driver
- **System Monitoring**:
  - Integrated nvtop GPU monitoring
  - System info display (lspci + driver versions)
- **Configuration Persistence**:
  - Remembers last used configuration

## ⚠️ Important Notes

- Designed specifically for **AMD-primary + NVIDIA-secondary** configurations
- Not recommended for NVIDIA-primary setups
- Always back up important data before use
- Review code if you have security concerns

## 📜 License & Legal

* Licensed under **GNU GPL v3.0 or later**
* **Trademarks:** NVIDIA, AMD, and DaVinci Resolve are trademarks of their respective owners
* This project is **not affiliated with or endorsed by** any hardware manufacturer

---

## 🛠️ Dependencies

```bash
# Core dependencies
sudo apt install zenity

# Recommended for full functionality
sudo apt install nvtop pciutils kmod policykit-1
```

---

## 📂 Installation

```bash
curl -O https://github.com/minto3792/opencl-switcher/blob/main/script/opencl-switcher.sh
chmod +x opencl-switcher.sh
sudo mv opencl-switcher.sh /usr/local/bin/opencl-switcher
```

---

## 🚀 Usage

Run from desktop session:
```bash
opencl-switcher
```

### GUI Options:
1. **OPENCL_CUDA** - NVIDIA only (ideal for Resolve)
2. **OPENCL_AMD** - AMD only (optimized for gaming)
3. **OPENCL_BOTH** - Enable both GPUs
4. **NOUVEAU_BLACKLIST** - Disable Nouveau driver
5. **NOUVEAU_WHITELIST** - Re-enable Nouveau
6. **DAVINCI_FIX** - Apply Resolve compatibility fix
7. **NVTOP** - Launch GPU monitoring tool
8. **INFO** - Show system GPU/driver info
9. **REBOOT** - Apply changes
10. **EXIT** - Close application

---

## 🎬 Recommended Workflows

### For Content Creation (DaVinci Resolve)
```mermaid
graph LR
    A[OPENCL_CUDA] --> B[DAVINCI_FIX] --> C[REBOOT]
```

### For Gaming
```mermaid
graph LR
    D[OPENCL_AMD] --> E[Launch Game]
```

### For Multi-GPU Workloads
```mermaid
graph LR
    F[OPENCL_BOTH] --> G[NVTOP Monitor] --> H[Run Application]
```

---

## 🧩 Technical Details

### Hybrid Configuration Notes:
- AMD GPU connected to primary display output
- NVIDIA GPU used for compute/rendering only
- Script modifies:
  - OpenCL vendor files: `/etc/OpenCL/vendors`
  - Nouveau config: `/etc/modprobe.d/blacklist-nouveau.conf`

### File Locations:
- **Configuration**: `~/.config/opencl-switcher.conf`
- **Log File**: `/tmp/opencl-switcher-gui.log`
- **DaVinci Fix**: Moves libraries in `/opt/resolve/libs` to `oldlibs/`

---

## ⚠️ Known Issues & Fixes

| Issue | Solution |
|-------|----------|
| Display not working after changes | Use console: `sudo opencl-switcher --nouveau-whitelist` |
| Resolve still crashing | Apply both OPENCL_CUDA and DAVINCI_FIX |
| AMD GPU not detected | Try OPENCL_BOTH mode + install `mesa-opencl-icd` |

---

## 🖼️ Additional Screenshots

### Info Window
![Info Window](https://github.com/minto3792/opencl-switcher/blob/b089791502d108c879c65c8a4b3353cd10a0247e/screenshots/info%20window.png)

### DaVinci Fix Applied
![DaVinci Fix](https://github.com/minto3792/opencl-switcher/blob/b089791502d108c879c65c8a4b3353cd10a0247e/screenshots/DaVinci%20Fix%20Confirmation.png)

---

## 🙏 Credits & License

* **License**: GNU GPL v3.0
* **Credits**:
  - [TechMimic YouTube](https://www.youtube-nocookie.com/embed/kMpm9kQfiAI) for DaVinci fix concept
  - Open Source community for continuous improvements
* **Disclaimer**: Use at your own risk. Not responsible for system damage.

---

## 🤝 Support & Contributions

* **Troubleshooting**: Check `/tmp/opencl-switcher-gui.log`
* **Issues**: GitHub issues with system details
* **Contributions**: PRs welcome under GPLv3+

```text
Designed specifically for AMD-primary + NVIDIA-secondary hybrid systems
```
