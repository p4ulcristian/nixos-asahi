#!/bin/bash
# Perfect NixOS - One-command installer for Apple Silicon Macs
# Usage: curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/asahi-install.sh | sh
set -e

REPO="p4ulcristian/nixos-asahi"
ISO_NAME="perfect-nixos-installer.iso"

echo ""
echo "  ╔═══════════════════════════════════════╗"
echo "  ║     Perfect NixOS for Apple Silicon    ║"
echo "  ║     Omarchy-style Hyprland Desktop     ║"
echo "  ╚═══════════════════════════════════════╝"
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script must be run from macOS."
    echo ""
    echo "If you're already in Linux, run:"
    echo "  curl -sL https://raw.githubusercontent.com/$REPO/main/install.sh | sudo bash"
    exit 1
fi

# Check for Apple Silicon
if [[ "$(uname -m)" != "arm64" ]]; then
    echo "This installer is for Apple Silicon Macs only."
    exit 1
fi

echo "[1/4] Checking for Asahi Linux partition..."
echo ""

# Check if Asahi stub is installed
if ! diskutil list | grep -q "Linux"; then
    echo "No Linux partition found. Installing Asahi Linux stub first..."
    echo ""
    echo "This will:"
    echo "  - Resize your macOS partition"
    echo "  - Create space for NixOS (50GB recommended)"
    echo "  - Install the UEFI boot environment"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi

    echo ""
    echo "Running Asahi Linux installer..."
    echo "Select 'UEFI environment only' when prompted."
    echo ""
    curl -sL https://alx.sh | sh

    echo ""
    echo "Asahi stub installed. Continuing with NixOS setup..."
fi

echo "[2/4] Downloading Perfect NixOS installer..."
echo ""

# Get latest release URL
RELEASE_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | grep "browser_download_url.*iso" | cut -d '"' -f 4)

if [[ -z "$RELEASE_URL" ]]; then
    echo "Error: Could not find release. Check https://github.com/$REPO/releases"
    exit 1
fi

# Download to temp
TEMP_DIR=$(mktemp -d)
ISO_PATH="$TEMP_DIR/$ISO_NAME"

echo "Downloading from: $RELEASE_URL"
curl -L -o "$ISO_PATH" "$RELEASE_URL"

echo ""
echo "[3/4] Preparing installer..."
echo ""

# Find available USB drives
echo "Available drives:"
diskutil list external

echo ""
read -p "Enter USB drive (e.g., disk2): " USB_DRIVE

if [[ -z "$USB_DRIVE" ]]; then
    echo ""
    echo "No drive selected. ISO saved to: $ISO_PATH"
    echo ""
    echo "To flash manually:"
    echo "  sudo dd if=$ISO_PATH of=/dev/r$USB_DRIVE bs=4m"
    echo ""
    echo "Or use balenaEtcher."
    exit 0
fi

echo ""
echo "WARNING: This will ERASE /dev/$USB_DRIVE"
read -p "Continue? (yes/no) " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted. ISO saved to: $ISO_PATH"
    exit 1
fi

# Unmount and flash
echo ""
echo "Flashing ISO to /dev/$USB_DRIVE..."
diskutil unmountDisk "/dev/$USB_DRIVE"
sudo dd if="$ISO_PATH" of="/dev/r$USB_DRIVE" bs=4m status=progress
sync

echo ""
echo "[4/4] Done!"
echo ""
echo "  ╔═══════════════════════════════════════╗"
echo "  ║              Next Steps:               ║"
echo "  ╠═══════════════════════════════════════╣"
echo "  ║  1. Reboot your Mac                   ║"
echo "  ║  2. Hold POWER button at startup      ║"
echo "  ║  3. Select 'Options' → USB drive      ║"
echo "  ║  4. Follow the installer              ║"
echo "  ╚═══════════════════════════════════════╝"
echo ""
echo "Enjoy Perfect NixOS!"
echo ""
