# M2 Mac hardware (Asahi)
{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;  # Apple Silicon

  # Asahi GPU & Audio
  hardware.asahi = {
    useExperimentalGPUDriver = true;
    experimentalGPUInstallMode = "replace";
    setupAsahiSound = true;
  };

  # Better WiFi for Apple
  networking.wireless.iwd.enable = true;

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
