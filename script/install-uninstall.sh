#!/bin/bash
#
# OpenCL Switcher GUI Installer / Uninstaller
#

INSTALL_PATH="/usr/local/bin/opencl-switcher"
DESKTOP_FILE="/usr/share/applications/opencl-switcher.desktop"
REPO_URL="https://raw.githubusercontent.com/minto3792/opencl-switcher/80f89cfa128e931e12c72266da12007f885e06c1/script/opencl-switcher.sh"

echo "=== OpenCL Switcher GUI Installer / Uninstaller ==="

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Main menu
echo "Select an option:"
echo "1) Install OpenCL Switcher GUI"
echo "2) Uninstall OpenCL Switcher GUI"
read -rp "Choice [1-2]: " choice

install_script() {
    echo "--- Installing OpenCL Switcher GUI ---"
    
    # Install dependencies
    echo "Installing dependencies..."
    if ! apt update; then
        echo "Failed to update package lists. Exiting."
        exit 1
    fi
    
    if ! apt install -y zenity nvtop; then
        echo "Failed to install dependencies. Exiting."
        exit 1
    fi

    # Download the script
    echo "Downloading script..."
    if ! curl -fsSL "$REPO_URL" -o "$INSTALL_PATH"; then
        echo "Failed to download script from $REPO_URL. Exiting."
        exit 1
    fi
    chmod +x "$INSTALL_PATH"
    echo "Script installed at $INSTALL_PATH"

    # Create desktop launcher
    echo "Creating desktop launcher..."
    mkdir -p "$(dirname "$DESKTOP_FILE")"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=OpenCL Switcher
Comment=GUI to switch OpenCL drivers
Exec=$INSTALL_PATH
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Utility;
Keywords=opencl;gpu;driver;
EOF

    echo "Desktop launcher created at $DESKTOP_FILE"
    echo "Installation complete!"
}

uninstall_script() {
    echo "--- Uninstalling OpenCL Switcher GUI ---"

    # Remove script
    if [[ -f "$INSTALL_PATH" ]]; then
        if rm -f "$INSTALL_PATH"; then
            echo "Removed $INSTALL_PATH"
        else
            echo "Failed to remove $INSTALL_PATH"
        fi
    else
        echo "Script not found at $INSTALL_PATH"
    fi

    # Remove desktop launcher
    if [[ -f "$DESKTOP_FILE" ]]; then
        if rm -f "$DESKTOP_FILE"; then
            echo "Removed desktop launcher $DESKTOP_FILE"
        else
            echo "Failed to remove $DESKTOP_FILE"
        fi
    else
        echo "Desktop launcher not found at $DESKTOP_FILE"
    fi

    echo "Uninstallation complete!"
    echo "Note: Dependencies (zenity, nvtop) were not removed"
    echo "to avoid breaking other applications."
}

case $choice in
    1) install_script ;;
    2) uninstall_script ;;
    *) echo "Invalid choice. Exiting." ;;
esac
