# M2 Mac hardware (Asahi)
{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;  # Apple Silicon

  # Asahi Audio (GPU now in mainline mesa)
  hardware.asahi.setupAsahiSound = true;

  # Use iwd as NetworkManager's WiFi backend (better for Apple)
  networking.networkmanager.wifi.backend = "iwd";

  # Filesystem (adjust labels after install)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
  };
}
