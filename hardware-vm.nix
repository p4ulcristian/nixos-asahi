# VM-specific hardware
{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = { device = "/dev/vda2"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/vda1"; fsType = "vfat"; };

  # SSH for debugging
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  networking.firewall.allowedTCPPorts = [ 22 ];
}
