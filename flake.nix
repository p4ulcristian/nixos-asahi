{
  description = "Perfect NixOS - Omarchy-style Hyprland for VM and M2 Mac";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-apple-silicon }:
  let
    system = "aarch64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {

    # ===== VM (for testing) =====
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
        ./hardware-vm.nix
        ./common.nix
      ];
    };

    # ===== Real M2 Mac (Asahi) =====
    nixosConfigurations.mac = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        nixos-apple-silicon.nixosModules.apple-silicon-support
        ./hardware-mac.nix
        ./common.nix
      ];
    };

    # ===== Installer image for Asahi =====
    nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        nixos-apple-silicon.nixosModules.apple-silicon-support
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ({ config, pkgs, lib, ... }: {
          # Disable ZFS (broken in current nixpkgs)
          boot.supportedFilesystems.zfs = lib.mkForce false;
          nixpkgs.config.allowBroken = true;
          # Include our config for post-install
          environment.etc."nixos-perfect/flake.nix".source = ./flake.nix;
          environment.etc."nixos-perfect/common.nix".source = ./common.nix;
          environment.etc."nixos-perfect/hardware-mac.nix".source = ./hardware-mac.nix;

          # Auto-install script
          environment.systemPackages = with pkgs; [
            git curl parted
          ];

          # Include install script
          environment.etc."install-perfect.sh" = {
            mode = "0755";
            text = builtins.readFile ./install.sh;
          };

          # Firmware for Apple Silicon
          hardware.asahi.useExperimentalGPUDriver = true;
          hardware.asahi.experimentalGPUInstallMode = "replace";

          # Networking
          networking.wireless.iwd.enable = true;
          networking.networkmanager.enable = true;

          isoImage.squashfsCompression = "zstd -Xcompression-level 6";
        })
      ];
    };

    # ===== Build targets =====
    packages.${system} = {
      vm = self.nixosConfigurations.vm.config.system.build.vm;
      mac-toplevel = self.nixosConfigurations.mac.config.system.build.toplevel;
      installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
      default = self.packages.${system}.vm;
    };
  };
}
