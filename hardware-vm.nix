# VM-specific hardware
{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = { device = "/dev/vda2"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/vda1"; fsType = "vfat"; };
}
