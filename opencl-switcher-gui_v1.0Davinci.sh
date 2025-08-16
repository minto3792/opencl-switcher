#!/bin/bash
# OpenCL Switcher GUI v1.0 (Revised for GPLv3 Compliance & Safer Operations)
# Copyright (C) 2025 Your Name
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# DISCLAIMER:
# This script modifies system driver configurations and may affect system stability.
# Review the code, back up your system, and use at your own risk.
#
# TRADEMARK NOTICE:
# NVIDIA and AMD are trademarks of their respective owners. This project is not
# affiliated with or endorsed by NVIDIA, AMD, or any other company.
#
# DAVINCI RESOLVE NOTICE:
# DaVinci Resolve is a trademark of Blackmagic Design Pty Ltd.
# This project is not affiliated with or endorsed by Blackmagic Design.
# The "DaVinci Fix" option only moves bundled GLib libraries inside /opt/resolve/libs
# into a backup folder to avoid conflicts with system libraries. No proprietary
# software is modified or redistributed.
#
# DEPENDENCIES:
#   - zenity (GUI dialogs)
#   - update-initramfs (Debian/Ubuntu; adapt for your distro as needed)
#   - pkexec (optional; for graphical elevation) or sudo
#   - lspci, modinfo (optional; for INFO dialog)
#
# SOURCE & CONTRIBUTIONS:
# Contributions are accepted under GPLv3-or-later.

set -euo pipefail

# ----------------------- Configuration -----------------------
VENDORS_DIR="/etc/OpenCL/vendors"
DISABLED_DIR="$VENDORS_DIR/disabled"
NVIDIA_ICD="nvidia.icd"
AMD_ICD_PATTERN="amdocl64*.icd"
MESA_ICD="mesa.icd"

MODPROBE_DIR="/etc/modprobe.d"
NOUVEAU_CONF="$MODPROBE_DIR/blacklist-nouveau.conf"

LOG_FILE="/tmp/opencl-switcher-gui.log"
CONFIG_FILE="${HOME}/.config/opencl-switcher.conf"
VERSION="1.0"
BRAND_NAME="OpenCL Switcher (unaffiliated)"

# Marker to identify files created by this script (used for safe cleanup)
CREATED_BY_MARKER="# Created by OpenCL Switcher"

# ----------------------- Utilities ---------------------------
script_realpath() {
    # Resolve the absolute path of this script for pkexec/sudo relaunch
    local src="${BASH_SOURCE[0]}"
    while [ -h "$src" ]; do
        local dir
        dir="$(cd -P "$(dirname "$src")" && pwd)"
        src="$(readlink "$src")"
        [[ "$src" != /* ]] && src="$dir/$src"
    done
    cd -P "$(dirname "$src")" && pwd
}

require_cmd() {
    local cmd="$1"; local hint="${2:-}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        [ -n "$hint" ] && hint=$'\n'"Hint: $hint"
        echo "Required command '$cmd' not found.$hint" >&2
        zenity --error --text="Required command '$cmd' not found.$hint" --width=420 || true
        exit 1
    fi
}

# ----------------------- Status Helpers ----------------------
get_status() {
    nvidia_enabled=0
    amd_enabled=0
    mesa_enabled=0
    nouveau_blacklisted=0

    [ -f "$VENDORS_DIR/$NVIDIA_ICD" ] && nvidia_enabled=1
    ls "$VENDORS_DIR"/$AMD_ICD_PATTERN >/dev/null 2>&1 && amd_enabled=1
    [ -f "$VENDORS_DIR/$MESA_ICD" ] && mesa_enabled=1
    [ -f "$NOUVEAU_CONF" ] && grep -qE '^\s*(#.*)?\bblacklist\s+nouveau\b' "$NOUVEAU_CONF" && nouveau_blacklisted=1
}

get_status_text() {
    get_status
    nv_indicator=$([ $nvidia_enabled -eq 1 ] && echo "●" || echo "○")
    amd_indicator=$([ $amd_enabled -eq 1 ] && echo "●" || echo "○")
    mesa_indicator=$([ $mesa_enabled -eq 1 ] && echo "●" || echo "○")
    nouveau_indicator=$([ $nouveau_blacklisted -eq 1 ] && echo "●" || echo "○")

    nv_color=$([ $nvidia_enabled -eq 1 ] && echo "green" || echo "red")
    amd_color=$([ $amd_enabled -eq 1 ] && echo "green" || echo "red")
    mesa_color=$([ $mesa_enabled -eq 1 ] && echo "green" || echo "red")
    nouveau_color=$([ $nouveau_blacklisted -eq 1 ] && echo "red" || echo "green")

    status_text="\n"
    status_text+="<span weight='bold'>       DRIVER       STATUS  </span>\n"
    status_text+="<span weight='bold'>──────────────────────────</span>\n"
    status_text+="<span foreground='$nv_color'> $nv_indicator NVIDIA CUDA    </span> $(if [ $nvidia_enabled -eq 1 ]; then echo "<span foreground='green'>ENABLED </span>"; else echo "<span foreground='red'>DISABLED</span>"; fi)\n"
    status_text+="<span foreground='$amd_color'> $amd_indicator AMD OpenCL    </span> $(if [ $amd_enabled -eq 1 ]; then echo "<span foreground='green'>ENABLED </span>"; else echo "<span foreground='red'>DISABLED</span>"; fi)\n"
    status_text+="<span foreground='$mesa_color'> $mesa_indicator Mesa         </span> $(if [ $mesa_enabled -eq 1 ]; then echo "<span foreground='green'>ENABLED </span>"; else echo "<span foreground='red'>DISABLED</span>"; fi)\n"
    status_text+="<span foreground='$nouveau_color'> $nouveau_indicator Nouveau      </span> $(if [ $nouveau_blacklisted -eq 1 ]; then echo "<span foreground='red'>BLOCKED </span>"; else echo "<span foreground='green'>ACTIVE  </span>"; fi)\n"
    echo "$status_text"
}

get_footer() {
    cat <<EOF

<span size='small' weight='light' style='italic'>
● = Active/Enabled  ○ = Inactive/Disabled
--------------------------------------------
<span weight='bold'>$BRAND_NAME</span> - Dual GPU Setup Manager v$VERSION
Designed for NVIDIA/AMD hybrid systems (no affiliation)
</span>
EOF
}

# ----------------------- Setup & Logging ---------------------
validate_paths() {
    for path in "$VENDORS_DIR" "$MODPROBE_DIR"; do
        if [[ ! -d "$path" ]]; then
            zenity --error --text="Critical directory missing: $path" --width=480
            exit 1
        fi
    done
    mkdir -p "$DISABLED_DIR"
}

setup_logging() {
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "=== OpenCL Switcher v$VERSION $(date) ==="
}

setup_prerequisites() {
    mkdir -p "$DISABLED_DIR"
}

# ----------------------- Nouveau Controls -------------------
blacklist_nouveau() {
    if [ -f "$NOUVEAU_CONF" ] && grep -qE '\bnouveau\b' "$NOUVEAU_CONF"; then
        zenity --info --title="Already Configured" \
            --text="Nouveau is already blacklisted in:\n$NOUVEAU_CONF" --width=380
        return 0
    fi

    {
        echo "$CREATED_BY_MARKER"
        echo "blacklist nouveau"
        echo "options nouveau modeset=0"
        echo "alias nouveau off"
    } | tee "$NOUVEAU_CONF" >/dev/null

    if [ ! -f "$NOUVEAU_CONF" ]; then
        zenity --error --text="Failed to create blacklist file!" --width=360
        return 1
    fi

    if command -v update-initramfs >/dev/null 2>&1; then
        if ! update-initramfs -u; then
            zenity --error --text="Failed to update initramfs!\nCheck logs: $LOG_FILE" --width=460
            return 1
        fi
    else
        zenity --warning --text="update-initramfs not found. Please rebuild your initramfs manually for changes to take effect." --width=520
    fi

    zenity --info --title="Success" --text="Nouveau driver blacklisted successfully." --width=360
}

whitelist_nouveau() {
    # Only remove the file we created (identified by marker), never arbitrary files.
    if [ -f "$NOUVEAU_CONF" ] && grep -qF "$CREATED_BY_MARKER" "$NOUVEAU_CONF"; then
        rm -f "$NOUVEAU_CONF"
    else
        zenity --warning --text="No script-created Nouveau blacklist found.\nManual review recommended in $MODPROBE_DIR." --width=520
    fi

    if command -v update-initramfs >/dev/null 2>&1; then
        update-initramfs -u || zenity --error --text="Failed to update initramfs. Changes may not take effect until rebuilt." --width=520
    fi
    zenity --info --title="Success" --text="Nouveau driver whitelisted (script-created file removed)." --width=420
}

# ----------------------- Driver Switching -------------------
switch_driver() {
    local src_dir="$1" dest_dir="$2" pattern="$3"
    local trans_dir
    trans_dir="$(mktemp -d)"

    if ! compgen -G "${src_dir}/${pattern}" >/dev/null; then
        zenity --warning --text="No ${pattern} files found in ${src_dir}" --width=360
        rmdir "$trans_dir"
        return 0
    fi

    mv "${src_dir}"/${pattern} "$trans_dir"/ 2>/dev/null || true
    mv "$trans_dir"/* "$dest_dir"/ 2>/dev/null || true
    rmdir "$trans_dir" || true
}

enable_config() {
    local mode="$1"
    mkdir -p "$DISABLED_DIR"
    case "$mode" in
        cuda)
            switch_driver "$VENDORS_DIR" "$DISABLED_DIR" "$AMD_ICD_PATTERN"
            switch_driver "$VENDORS_DIR" "$DISABLED_DIR" "$MESA_ICD"
            switch_driver "$DISABLED_DIR" "$VENDORS_DIR" "$NVIDIA_ICD"
            ;;
        amd)
            switch_driver "$VENDORS_DIR" "$DISABLED_DIR" "$NVIDIA_ICD"
            switch_driver "$DISABLED_DIR" "$VENDORS_DIR" "$AMD_ICD_PATTERN"
            switch_driver "$DISABLED_DIR" "$VENDORS_DIR" "$MESA_ICD"
            ;;
        both)
            switch_driver "$DISABLED_DIR" "$VENDORS_DIR" "$AMD_ICD_PATTERN"
            switch_driver "$DISABLED_DIR" "$VENDORS_DIR" "$MESA_ICD"
            switch_driver "$DISABLED_DIR" "$VENDORS_DIR" "$NVIDIA_ICD"
            ;;
    esac
}

show_reboot_dialog() {
    zenity --question --title="Reboot Required" \
        --text="A system reboot is required for changes to take effect.\n\nReboot now?" \
        --width=380 --ok-label="Reboot" --cancel-label="Later"
    [ $? -eq 0 ] && systemctl reboot
}

save_preferences() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "LAST_MODE=$1" > "$CONFIG_FILE"
}

load_preferences() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
    echo "${LAST_MODE:-none}"
}

show_system_info() {
    gpu_info=$(lspci | grep -iE 'vga|3d' | sed 's/.*: //' 2>/dev/null || true)
    nv_driver=$(modinfo nvidia 2>/dev/null | awk '/^version:/{print $2}')
    amd_driver=$(modinfo amdgpu 2>/dev/null | awk '/^version:/{print $2}')

    zenity --info --title="System Information" \
        --text="<b>GPU Devices:</b>\n${gpu_info:-Not detected}\n\n<b>Driver Versions:</b>\n- NVIDIA: ${nv_driver:-Not loaded}\n- AMD: ${amd_driver:-Not loaded}\n\n<b>Log File:</b> $LOG_FILE" \
        --width=560
}

# ----------------------- DaVinci Resolve Fix -------------------
davinci_fix() {
    local davinci_dir="/opt/resolve/libs"
    local backup_dir="oldlibs"

    if [[ ! -d "$davinci_dir" ]]; then
        zenity --error --title="DaVinci Fix" \
            --text="DaVinci Resolve not found at:\n$davinci_dir\n\nFix cannot be applied." --width=500
        return 1
    fi

    # Make backup dir
    mkdir -p "$davinci_dir/$backup_dir"

    # Move potential conflicting libraries into backup (if present)
    local moved_any=0
    pushd "$davinci_dir" >/dev/null || return 1
    for pattern in "libglib*" "libgio*" "libgmodule*" "libgobject*"; do
        if compgen -G "$pattern" >/dev/null; then
            mv $pattern "$backup_dir"/ 2>/dev/null || true
            moved_any=1
        fi
    done
    popd >/dev/null || true

    if [[ "$moved_any" -eq 1 ]]; then
        zenity --info --title="DaVinci Fix Applied" \
            --text="Bundled GLib libraries were moved to:\n$davinci_dir/$backup_dir\n\nDaVinci Resolve should now prefer system libraries.\nTo restore, move files back from 'oldlibs/'." \
            --width=520
    else
        zenity --info --title="DaVinci Fix" \
            --text="No matching bundled GLib libraries found to move.\nNothing changed." \
            --width=420
    fi
}

# ----------------------- GUI -------------------------------
show_gui() {
    last_mode=$(load_preferences)
    while true; do
        choice=$(zenity --list \
            --title="$BRAND_NAME v$VERSION" \
            --text="<b>Current Status:</b>\n$(get_status_text)\n\nLast applied mode: ${last_mode^^}\n\n<i>This tool is community-provided, unaffiliated with vendors.</i>" \
            --width=760 --height=560 \
            --column="Option" --column="Description" \
            "OPENCL_CUDA" "Enable NVIDIA CUDA only (e.g., for Resolve)" \
            "OPENCL_AMD" "Enable AMD/Mesa only (e.g., for gaming)" \
            "OPENCL_BOTH" "Enable both NVIDIA and AMD/Mesa" \
            "NOUVEAU_BLACKLIST" "Blacklist Nouveau driver (often required for proprietary NVIDIA)" \
            "NOUVEAU_WHITELIST" "Whitelist Nouveau driver (revert script-created blacklist)" \
            "DAVINCI_FIX" "Apply DaVinci Resolve library fix (move bundled glib/gio libs to oldlibs/)" \
            "INFO" "Show system configuration details" \
            "REBOOT" "Reboot system to apply changes" \
            "EXIT" "Close the application" \
            --hide-header --ok-label="Select" --cancel-label="Quit")

        if [ $? -ne 0 ]; then
            exit 0
        fi

        case "$choice" in
            OPENCL_CUDA)
                enable_config cuda
                save_preferences cuda
                last_mode=cuda
                zenity --info --title="Success" --text="NVIDIA CUDA enabled\nAMD/Mesa disabled" --width=360
                ;;
            OPENCL_AMD)
                enable_config amd
                save_preferences amd
                last_mode=amd
                zenity --info --title="Success" --text="AMD/Mesa enabled\nNVIDIA CUDA disabled" --width=360
                ;;
            OPENCL_BOTH)
                enable_config both
                save_preferences both
                last_mode=both
                zenity --info --title="Success" --text="Both NVIDIA CUDA and AMD/Mesa enabled" --width=360
                ;;
            NOUVEAU_BLACKLIST)
                blacklist_nouveau
                show_reboot_dialog
                ;;
            NOUVEAU_WHITELIST)
                whitelist_nouveau
                show_reboot_dialog
                ;;
            DAVINCI_FIX)
                davinci_fix
                ;;
            INFO)
                show_system_info
                ;;
            REBOOT)
                show_reboot_dialog
                ;;
            EXIT)
                exit 0
                ;;
        esac
    done
}

# ----------------------- Entry Point ------------------------
# GUI presence
if ! command -v zenity >/dev/null 2>&1; then
    echo "Zenity is required but not installed. Try: sudo apt install zenity"
    exit 1
fi
if [ -z "${DISPLAY:-}" ]; then
    echo "This script requires a GUI environment. Please run from a desktop session."
    exit 1
fi

# Elevation with safe path resolution
if [ "$(id -u)" -ne 0 ]; then
    script_dir="$(script_realpath)"
    script_path="$script_dir/$(basename "$0")"
    if command -v pkexec >/dev/null 2>&1; then
        pkexec env DISPLAY="$DISPLAY" XAUTHORITY="${XAUTHORITY:-}" "$script_path"
    else
        require_cmd sudo "Install 'policykit-1' for pkexec or use sudo."
        sudo -E env DISPLAY="$DISPLAY" XAUTHORITY="${XAUTHORITY:-}" "$script_path"
    fi
    exit $?
fi

# Now root
validate_paths
setup_logging
setup_prerequisites

# Warn if update-initramfs missing (non-fatal; distro-specific)
if ! command -v update-initramfs >/dev/null 2>&1; then
    echo "Note: update-initramfs not found; if your distro uses dracut or mkinitcpio, rebuild initramfs accordingly." | tee -a "$LOG_FILE"
fi

show_gui

