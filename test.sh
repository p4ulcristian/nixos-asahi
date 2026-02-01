#!/usr/bin/env bash
# Test Perfect NixOS VM build
set -e
cd "$(dirname "$0")"

echo "Building VM..."
nix --extra-experimental-features "nix-command flakes" build .#vm

echo "Starting VM (login: paul / nixos)..."
./result/bin/run-*-vm
