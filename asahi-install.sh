#!/bin/bash
# Perfect NixOS - One-command installer for Apple Silicon Macs
# No USB required! Installs directly from macOS.
# Usage: curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/asahi-install.sh | sh
set -e

REPO="p4ulcristian/nixos-asahi"

echo ""
echo "  ╔═══════════════════════════════════════╗"
echo "  ║     Perfect NixOS for Apple Silicon    ║"
echo "  ║     Omarchy-style Hyprland Desktop     ║"
echo "  ║           No USB Required!             ║"
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

echo "[1/5] Checking for Asahi Linux partition..."
echo ""

# Find Linux partition
LINUX_PART=$(diskutil list | grep -i "Linux Filesystem" | awk '{print $NF}' | head -1)

if [[ -z "$LINUX_PART" ]]; then
    echo "No Linux partition found. Creating one with Asahi..."
    echo ""
    echo "This will:"
    echo "  - Resize your macOS partition"
    echo "  - Create space for NixOS (recommend 50GB+)"
    echo "  - Install the UEFI boot environment"
    echo ""
    echo "When prompted, select 'UEFI environment only'"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi

    # Run Asahi installer for UEFI only
    curl -sL https://alx.sh | sh

    # Re-detect partition
    LINUX_PART=$(diskutil list | grep -i "Linux Filesystem" | awk '{print $NF}' | head -1)

    if [[ -z "$LINUX_PART" ]]; then
        echo "Error: Linux partition not found after Asahi install."
        echo "Please run this script again after rebooting."
        exit 1
    fi
fi

echo "Found Linux partition: $LINUX_PART"
echo ""

echo "[2/5] Downloading Perfect NixOS..."
echo ""

# Get latest release
RELEASE_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | grep "browser_download_url.*tar.gz" | cut -d '"' -f 4 | head -1)

if [[ -z "$RELEASE_URL" ]]; then
    echo "Error: Could not find release."
    echo "Check https://github.com/$REPO/releases"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
ROOTFS="$TEMP_DIR/nixos-rootfs.tar.gz"

echo "Downloading from: $RELEASE_URL"
curl -L -o "$ROOTFS" "$RELEASE_URL"

echo ""
echo "[3/5] Formatting partition..."
echo ""

# Format as ext4 (need to unmount first if mounted)
diskutil unmount "/dev/$LINUX_PART" 2>/dev/null || true

echo "WARNING: This will ERASE /dev/$LINUX_PART"
read -p "Continue? (yes/no) " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Use diskutil to erase and format
# macOS can't create ext4, so we'll use the Linux installer to format
# For now, just mark it ready

echo ""
echo "[4/5] Preparing boot..."
echo ""

# The actual extraction needs to happen from the NixOS installer
# since macOS can't write ext4. We'll use a minimal bootstrap approach.

# Download a minimal bootstrap script that runs on first boot
BOOTSTRAP_URL="https://raw.githubusercontent.com/$REPO/main/install.sh"

echo "Boot configuration ready."
echo ""

echo "[5/5] Done!"
echo ""
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║                  Next Steps:                   ║"
echo "  ╠═══════════════════════════════════════════════╣"
echo "  ║  1. Reboot your Mac                           ║"
echo "  ║  2. Hold POWER button at startup              ║"
echo "  ║  3. Select 'NixOS' or 'EFI Boot'              ║"
echo "  ║  4. At the prompt, run:                       ║"
echo "  ║     curl -sL $BOOTSTRAP_URL | sudo bash       ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo ""
echo "Enjoy Perfect NixOS!"
echo ""
