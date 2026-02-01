#!/usr/bin/env bash
# Perfect NixOS - One-liner installer for Apple Silicon Macs
# Usage: curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/install.sh | sudo bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
error() { echo -e "${RED}[!]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] || error "Run as root: curl ... | sudo bash"

echo ""
echo "  Perfect NixOS Installer"
echo "  ========================"
echo ""

# ===== AUTO-DETECT ASAHI PARTITION =====
# Asahi creates a Linux partition (usually the last large one on nvme)
DISK="/dev/nvme0n1"
[[ -b "$DISK" ]] || error "No NVMe disk found. Is this an Apple Silicon Mac?"

# Find EFI partition (type c12a7328-f81f-11d2-ba4b-00a0c93ec93b)
EFI_PART=$(lsblk -ln -o NAME,PARTTYPE "$DISK" 2>/dev/null | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | awk '{print $1}' | head -1)
[[ -n "$EFI_PART" ]] || error "No EFI partition found. Run 'curl https://alx.sh | sh' from macOS first."
EFI_PART="/dev/$EFI_PART"

# Find Linux partition (largest unformatted or ext4 partition, not EFI/Apple)
ROOT_PART=$(lsblk -ln -o NAME,SIZE,FSTYPE,PARTTYPE "$DISK" 2>/dev/null | grep -v "c12a7328" | grep -v "48465300" | grep -v "7C3457EF" | tail -1 | awk '{print $1}')
[[ -n "$ROOT_PART" ]] || error "No Linux partition found. Run 'curl https://alx.sh | sh' from macOS first."
ROOT_PART="/dev/$ROOT_PART"

info "Detected: EFI=$EFI_PART ROOT=$ROOT_PART"
echo ""
read -rp "Install Perfect NixOS to $ROOT_PART? This will ERASE it. (yes/no): " CONFIRM
[[ "$CONFIRM" == "yes" ]] || error "Aborted"

# ===== FORMAT & MOUNT =====
info "Formatting $ROOT_PART..."
mkfs.ext4 -F -L nixos "$ROOT_PART"

info "Mounting filesystems..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

# ===== CLONE CONFIG =====
info "Downloading config..."
mkdir -p /mnt/etc/nixos
cd /mnt/etc/nixos
for f in flake.nix flake.lock common.nix hardware-mac.nix; do
    curl -sLO "https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/$f"
done

# ===== INSTALL =====
info "Installing NixOS (this takes a while)..."
nixos-install --flake /mnt/etc/nixos#mac --no-root-passwd

# ===== SET PASSWORD =====
info "Set password for 'paul':"
nixos-enter --root /mnt -c "passwd paul"

# ===== DONE =====
echo ""
success "Done! Reboot and select NixOS from boot menu."
echo ""
echo "  ALT+Return = terminal"
echo "  ALT+D      = launcher"
echo "  ALT+Q      = close"
echo ""
