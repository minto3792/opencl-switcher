#!/bin/bash
#
# OpenCL Switcher GUI Installer / Uninstaller (Zenity Version)
#

INSTALL_PATH="/usr/local/bin/opencl-switcher"
DESKTOP_FILE="/usr/share/applications/opencl-switcher.desktop"
REPO_URL="https://raw.githubusercontent.com/minto3792/opencl-switcher/80f89cfa128e931e12c72266da12007f885e06c1/script/opencl-switcher.sh"

# Initial popup to request root access
zenity --question --title="OpenCL Switcher Installer" \
    --text="This installer requires root privileges to continue.\n\nDo you want to proceed with authentication?" \
    --width=400 --height=150

if [[ $? -ne 0 ]]; then
    zenity --info --title="Cancelled" --text="Installation cancelled by user."
    exit 0
fi

# Get sudo password
PASSWORD=$(zenity --password --title="Authentication Required")
if [[ -z "$PASSWORD" ]]; then
    zenity --error --title="Error" --text="Authentication failed. Please provide your password."
    exit 1
fi

# Verify sudo access
echo "$PASSWORD" | sudo -S echo "Testing sudo access..." 2>/dev/null
if [[ $? -ne 0 ]]; then
    zenity --error --title="Error" --text="Authentication failed. Incorrect password or insufficient privileges."
    exit 1
fi

# Main menu
choice=$(zenity --list --title="OpenCL Switcher" \
    --text="Select an option:" \
    --column="Option" --column="Action" \
    1 "Install OpenCL Switcher GUI" \
    2 "Uninstall OpenCL Switcher GUI" \
    --height=200 --width=400)

if [[ $? -ne 0 ]]; then
    zenity --info --title="Cancelled" --text="Operation cancelled by user."
    exit 0
fi

install_script() {
    (
        echo "10" ; sleep 1
        echo "# Updating package lists..."
        echo "$PASSWORD" | sudo -S apt update 2>&1 | tee -a /tmp/opencl-install.log
        
        echo "30" ; sleep 1
        echo "# Installing dependencies (zenity, nvtop)..."
        echo "$PASSWORD" | sudo -S apt install -y zenity nvtop 2>&1 | tee -a /tmp/opencl-install.log
        
        echo "50" ; sleep 1
        echo "# Downloading script from GitHub..."
        echo "$PASSWORD" | sudo -S curl -fsSL "$REPO_URL" -o "$INSTALL_PATH" 2>&1 | tee -a /tmp/opencl-install.log
        
        echo "70" ; sleep 1
        echo "# Setting executable permissions..."
        echo "$PASSWORD" | sudo -S chmod +x "$INSTALL_PATH"
        
        echo "80" ; sleep 1
        echo "# Creating desktop launcher..."
        echo "$PASSWORD" | sudo -S mkdir -p "$(dirname "$DESKTOP_FILE")"
        
        # Create a temporary file for the desktop entry
        TEMP_DESKTOP=$(mktemp)
        cat > "$TEMP_DESKTOP" << EOF
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
        
        # Move the temporary file to the destination with sudo
        echo "$PASSWORD" | sudo -S mv "$TEMP_DESKTOP" "$DESKTOP_FILE" 2>&1 | tee -a /tmp/opencl-install.log
        echo "$PASSWORD" | sudo -S chmod 644 "$DESKTOP_FILE"
        
        echo "100" ; sleep 1
        echo "# Installation complete!"
    ) | zenity --progress \
        --title="Installing OpenCL Switcher" \
        --text="Starting installation..." \
        --percentage=0 \
        --auto-close \
        --width=400
    
    if [[ $? -eq 0 ]]; then
        zenity --info --title="Success" --text="Installation completed successfully!\n\nScript installed at: $INSTALL_PATH\nDesktop launcher at: $DESKTOP_FILE" --width=400
    else
        zenity --error --title="Error" --text="Installation failed. Check /tmp/opencl-install.log for details." --width=400
    fi
}

uninstall_script() {
    if zenity --question --title="Confirm Uninstall" --text="Are you sure you want to uninstall OpenCL Switcher?" --width=400; then
        (
            echo "50"
            echo "# Removing installation files..."
            echo "$PASSWORD" | sudo -S rm -f "$INSTALL_PATH" 2>&1 | tee -a /tmp/opencl-uninstall.log
            echo "$PASSWORD" | sudo -S rm -f "$DESKTOP_FILE" 2>&1 | tee -a /tmp/opencl-uninstall.log
            
            echo "100"
            echo "# Uninstallation complete!"
        ) | zenity --progress \
            --title="Uninstalling OpenCL Switcher" \
            --text="Removing files..." \
            --percentage=0 \
            --auto-close \
            --width=400
        
        zenity --info --title="Success" --text="Uninstallation completed!\n\nNote: Dependencies (zenity, nvtop) were not removed to avoid breaking other applications." --width=400
    else
        zenity --info --title="Cancelled" --text="Uninstallation cancelled." --width=300
    fi
}

case $choice in
    1) install_script ;;
    2) uninstall_script ;;
    *) zenity --error --title="Error" --text="Invalid selection. Exiting." ;;
esac
