#!/usr/bin/env bash
# Perfect NixOS - Bootstrap installer for Apple Silicon Macs
# Run from NixOS installer: curl -sL <raw-url> | bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
error() { echo -e "${RED}[!]${NC} $1"; exit 1; }

# ===== PRE-FLIGHT CHECKS =====
[[ $EUID -eq 0 ]] || error "Run as root: sudo bash install.sh"
[[ -d /sys/firmware/efi ]] || error "EFI boot required"

info "Perfect NixOS Installer for Apple Silicon"
echo ""

# ===== DETECT DISK =====
info "Available disks:"
lsblk -d -o NAME,SIZE,MODEL | grep -E "nvme|sd"
echo ""
read -rp "Enter target disk (e.g., nvme0n1): " DISK
DISK="/dev/${DISK}"
[[ -b "$DISK" ]] || error "Disk $DISK not found"

# ===== PARTITION LAYOUT =====
# Asahi already creates the EFI partition, we just need root
info "Checking partition layout..."

# Find existing EFI partition (Asahi creates this)
EFI_PART=$(lsblk -ln -o NAME,PARTTYPE "$DISK" | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | awk '{print $1}' | head -1)

if [[ -z "$EFI_PART" ]]; then
    info "No EFI partition found. Creating partitions..."
    echo ""
    echo "WARNING: This will erase $DISK"
    read -rp "Continue? (yes/no): " CONFIRM
    [[ "$CONFIRM" == "yes" ]] || error "Aborted"

    parted -s "$DISK" -- mklabel gpt
    parted -s "$DISK" -- mkpart ESP fat32 1MiB 512MiB
    parted -s "$DISK" -- set 1 esp on
    parted -s "$DISK" -- mkpart primary 512MiB 100%

    # Determine partition naming
    if [[ "$DISK" == *"nvme"* ]]; then
        EFI_PART="${DISK}p1"
        ROOT_PART="${DISK}p2"
    else
        EFI_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    fi

    info "Formatting partitions..."
    mkfs.fat -F32 "$EFI_PART"
    mkfs.ext4 -L nixos "$ROOT_PART"
else
    EFI_PART="/dev/$EFI_PART"
    info "Found existing EFI partition: $EFI_PART"

    # Find or create root partition
    echo ""
    lsblk -ln -o NAME,SIZE,FSTYPE "$DISK"
    read -rp "Enter root partition (e.g., nvme0n1p5): " ROOT_PART_NAME
    ROOT_PART="/dev/$ROOT_PART_NAME"
    [[ -b "$ROOT_PART" ]] || error "Partition $ROOT_PART not found"

    read -rp "Format $ROOT_PART as ext4? (yes/no): " FORMAT
    if [[ "$FORMAT" == "yes" ]]; then
        mkfs.ext4 -L nixos "$ROOT_PART"
    fi
fi

# ===== MOUNT =====
info "Mounting filesystems..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

success "Mounted: $ROOT_PART -> /mnt, $EFI_PART -> /mnt/boot"

# ===== CLONE CONFIG =====
info "Cloning Perfect NixOS configuration..."
nix-shell -p git --run "git clone https://github.com/p4ulcristian/nixos-asahi.git /mnt/etc/nixos" || {
    # Fallback: create config directory and copy files
    mkdir -p /mnt/etc/nixos
    info "Clone failed. Downloading files directly..."
    cd /mnt/etc/nixos
    for f in flake.nix flake.lock common.nix hardware-mac.nix; do
        curl -sLO "https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/$f" || true
    done
}

# ===== GENERATE HARDWARE CONFIG =====
info "Generating hardware configuration..."
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hardware-mac-generated.nix

# Merge with existing hardware-mac.nix
cat >> /mnt/etc/nixos/hardware-mac.nix << 'EOF'

# Auto-generated hardware (merge as needed):
# See hardware-mac-generated.nix for detected settings
EOF

# ===== CUSTOMIZE =====
echo ""
read -rp "Enter username (default: paul): " USERNAME
USERNAME="${USERNAME:-paul}"

if [[ "$USERNAME" != "paul" ]]; then
    info "Updating username to $USERNAME..."
    sed -i "s/paul/$USERNAME/g" /mnt/etc/nixos/common.nix
fi

read -rp "Enter hostname (default: perfect): " HOSTNAME
HOSTNAME="${HOSTNAME:-perfect}"

if [[ "$HOSTNAME" != "perfect" ]]; then
    sed -i "s/hostName = \"perfect\"/hostName = \"$HOSTNAME\"/" /mnt/etc/nixos/common.nix
fi

# ===== INSTALL =====
info "Installing NixOS (this will take a while)..."
echo ""

nixos-install --flake /mnt/etc/nixos#mac --no-root-passwd

# ===== SET PASSWORD =====
info "Setting user password..."
nixos-enter --root /mnt -c "passwd $USERNAME"

# ===== DONE =====
echo ""
success "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Reboot: reboot"
echo "  2. Select NixOS from boot menu"
echo "  3. Login as $USERNAME"
echo "  4. Enjoy your Perfect NixOS + Hyprland setup!"
echo ""
echo "Default keybindings (ALT is the modifier):"
echo "  ALT+Return  - Terminal"
echo "  ALT+D       - App launcher"
echo "  ALT+Q       - Close window"
echo "  ALT+1-6     - Switch workspace"
echo ""
