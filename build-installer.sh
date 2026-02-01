#!/usr/bin/env bash
# Build an offline installer USB for Apple Silicon Mac
# The USB will contain everything - no network needed during install
set -e

cd "$(dirname "$0")"

echo "Building NixOS system for Mac..."
nix --extra-experimental-features "nix-command flakes" build .#mac-toplevel -o result-mac

echo "Creating installer package..."
mkdir -p installer
cp -L result-mac installer/system

# Create offline install script
cat > installer/install-offline.sh << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
error() { echo -e "${RED}[!]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] || error "Run as root"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSTEM="$SCRIPT_DIR/system"

[[ -d "$SYSTEM" ]] || error "System not found. Run from installer USB."

# Find disk
DISK="/dev/nvme0n1"
[[ -b "$DISK" ]] || error "No NVMe disk found"

# Find partitions
EFI_PART=$(lsblk -ln -o NAME,PARTTYPE "$DISK" | grep -i "c12a7328" | awk '{print $1}' | head -1)
[[ -n "$EFI_PART" ]] || error "No EFI partition. Run Asahi installer first."
EFI_PART="/dev/$EFI_PART"

ROOT_PART=$(lsblk -ln -o NAME,PARTTYPE "$DISK" | grep -v "c12a7328\|48465300\|7C3457EF" | tail -1 | awk '{print $1}')
[[ -n "$ROOT_PART" ]] || error "No Linux partition found"
ROOT_PART="/dev/$ROOT_PART"

info "EFI: $EFI_PART  ROOT: $ROOT_PART"
read -rp "Install to $ROOT_PART? (yes/no): " CONFIRM
[[ "$CONFIRM" == "yes" ]] || error "Aborted"

info "Formatting..."
mkfs.ext4 -F -L nixos "$ROOT_PART"

info "Mounting..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

info "Copying system (this takes a while)..."
mkdir -p /mnt/nix/store
cp -a "$SYSTEM"/* /mnt/

info "Installing bootloader..."
NIXOS_INSTALL_BOOTLOADER=1 chroot /mnt /nix/var/nix/profiles/system/bin/switch-to-configuration boot

info "Setting up user..."
chroot /mnt passwd paul

success "Done! Reboot and select NixOS."
SCRIPT

chmod +x installer/install-offline.sh

echo ""
echo "Done! Copy 'installer/' folder to a USB drive."
echo "Boot any Linux on Mac, then run: sudo ./install-offline.sh"
