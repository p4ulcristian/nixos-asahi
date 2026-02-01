#!/usr/bin/env bash
# Perfect NixOS - One-liner installer
# Works on: Apple Silicon Mac (Asahi) or VM
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

# ===== DETECT ENVIRONMENT =====
if [[ -d /sys/firmware/devicetree/base ]] && grep -q "Apple" /sys/firmware/devicetree/base/compatible 2>/dev/null; then
    MODE="mac"
    FLAKE_TARGET="mac"
    info "Detected: Apple Silicon Mac"
elif systemd-detect-virt -q 2>/dev/null; then
    MODE="vm"
    FLAKE_TARGET="vm"
    info "Detected: Virtual Machine ($(systemd-detect-virt))"
else
    MODE="vm"
    FLAKE_TARGET="vm"
    info "Detected: Generic system (using VM config)"
fi

# ===== FIND DISK =====
if [[ -b /dev/vda ]]; then
    DISK="/dev/vda"
elif [[ -b /dev/nvme0n1 ]]; then
    DISK="/dev/nvme0n1"
elif [[ -b /dev/sda ]]; then
    DISK="/dev/sda"
else
    error "No disk found"
fi
info "Target disk: $DISK"

# ===== PARTITION DETECTION / CREATION =====
if [[ "$MODE" == "mac" ]]; then
    # Mac: Asahi already created partitions
    EFI_PART=$(lsblk -ln -o NAME,PARTTYPE "$DISK" 2>/dev/null | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | awk '{print $1}' | head -1)
    [[ -n "$EFI_PART" ]] || error "No EFI partition. Run 'curl https://alx.sh | sh' from macOS first."
    EFI_PART="/dev/$EFI_PART"

    ROOT_PART=$(lsblk -ln -o NAME,SIZE,FSTYPE,PARTTYPE "$DISK" 2>/dev/null | grep -v "c12a7328" | grep -v "48465300" | grep -v "7C3457EF" | tail -1 | awk '{print $1}')
    [[ -n "$ROOT_PART" ]] || error "No Linux partition found."
    ROOT_PART="/dev/$ROOT_PART"
else
    # VM: Create partitions
    info "Creating partitions on $DISK..."

    echo ""
    echo "WARNING: This will ERASE $DISK"
    read -rp "Continue? (yes/no): " CONFIRM
    [[ "$CONFIRM" == "yes" ]] || error "Aborted"

    parted -s "$DISK" -- mklabel gpt
    parted -s "$DISK" -- mkpart ESP fat32 1MiB 512MiB
    parted -s "$DISK" -- set 1 esp on
    parted -s "$DISK" -- mkpart primary 512MiB 100%

    sleep 1  # Wait for kernel to pick up partitions

    if [[ "$DISK" == "/dev/vda" ]]; then
        EFI_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    elif [[ "$DISK" == *"nvme"* ]]; then
        EFI_PART="${DISK}p1"
        ROOT_PART="${DISK}p2"
    else
        EFI_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    fi

    info "Formatting EFI partition..."
    mkfs.fat -F32 "$EFI_PART"
fi

info "Partitions: EFI=$EFI_PART ROOT=$ROOT_PART"

if [[ "$MODE" == "mac" ]]; then
    echo ""
    read -rp "Install to $ROOT_PART? This will ERASE it. (yes/no): " CONFIRM
    [[ "$CONFIRM" == "yes" ]] || error "Aborted"
fi

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
for f in flake.nix flake.lock common.nix hardware-mac.nix hardware-vm.nix; do
    curl -sLO "https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/$f"
done

# ===== INSTALL =====
info "Installing NixOS with $FLAKE_TARGET config..."
info "(This takes a while - downloading packages)"
nixos-install --flake "/mnt/etc/nixos#$FLAKE_TARGET" --no-root-passwd

# ===== SET PASSWORD =====
info "Set password for 'paul':"
nixos-enter --root /mnt -c "passwd paul"

# ===== DONE =====
echo ""
success "Done! Reboot and enjoy Perfect NixOS."
echo ""
echo "  ALT+Return = terminal"
echo "  ALT+D      = launcher"
echo "  ALT+Q      = close"
echo ""
