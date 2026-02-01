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
LINUX_DISK=$(diskutil list | grep -B 5 "Linux Filesystem" | grep "/dev/disk" | awk '{print $1}' | head -1)
LINUX_PART=$(diskutil list | grep "Linux Filesystem" | awk '{print $NF}' | head -1)

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
    /bin/bash -c "$(curl -fsSL https://alx.sh)"

    echo ""
    echo "Asahi setup complete. Please run this script again."
    exit 0
fi

LINUX_DISK_PART="${LINUX_DISK}${LINUX_PART}"
echo "Found Linux partition: $LINUX_DISK_PART"
echo ""

echo "[2/5] Downloading Perfect NixOS image..."
echo ""

# Get latest release
RELEASE_JSON=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest")
IMAGE_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url.*img.gz" | cut -d '"' -f 4 | head -1)

if [[ -z "$IMAGE_URL" ]]; then
    echo "Error: Could not find release image."
    echo "Check https://github.com/$REPO/releases"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
IMAGE_GZ="$TEMP_DIR/perfect-nixos.img.gz"
IMAGE="$TEMP_DIR/perfect-nixos.img"

echo "Downloading: $IMAGE_URL"
curl -L --progress-bar -o "$IMAGE_GZ" "$IMAGE_URL"

echo ""
echo "[3/5] Extracting image..."
gunzip "$IMAGE_GZ"

echo ""
echo "[4/5] Writing to partition..."
echo ""
echo "WARNING: This will ERASE $LINUX_DISK_PART"
echo "Make sure this is the correct Linux partition!"
diskutil list "$LINUX_DISK"
echo ""
read -p "Type 'yes' to continue: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Unmount if mounted
diskutil unmount "$LINUX_DISK_PART" 2>/dev/null || true
diskutil unmountDisk "$LINUX_DISK" 2>/dev/null || true

# Write image
echo ""
echo "Writing NixOS to $LINUX_DISK_PART..."
echo "(This may take a few minutes)"
sudo dd if="$IMAGE" of="$LINUX_DISK_PART" bs=4m status=progress
sync

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "[5/5] Done!"
echo ""
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║              Installation Complete!            ║"
echo "  ╠═══════════════════════════════════════════════╣"
echo "  ║  1. Reboot your Mac                           ║"
echo "  ║  2. Hold POWER button at startup              ║"
echo "  ║  3. Select 'NixOS' from boot menu             ║"
echo "  ║  4. Login: paul / nixos                       ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo ""
echo "Enjoy Perfect NixOS with Hyprland!"
echo ""
