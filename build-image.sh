#!/usr/bin/env bash
# Build a flashable NixOS disk image for Apple Silicon Mac
# Then dd it to the Mac's Linux partition
set -e

cd "$(dirname "$0")"

echo "Building NixOS disk image for Mac..."

# Build raw disk image using nixos-generators or manual approach
nix --extra-experimental-features "nix-command flakes" build .#mac-image

echo ""
echo "Done! Image: ./result"
echo ""
echo "To flash on Mac:"
echo "  1. Boot macOS"
echo "  2. Find Linux partition: diskutil list"
echo "  3. Flash: sudo dd if=result/nixos.img of=/dev/diskXsY bs=4M status=progress"
echo "  4. Reboot and select NixOS"
