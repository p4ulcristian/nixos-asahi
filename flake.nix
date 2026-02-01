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

    # ===== Raw disk image for direct dd from macOS =====
    nixosConfigurations.diskImage = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        nixos-apple-silicon.nixosModules.apple-silicon-support
        ./hardware-mac.nix
        ./common.nix
        ({ config, pkgs, lib, modulesPath, ... }: {
          imports = [ "${modulesPath}/image/repart.nix" ];

          boot.supportedFilesystems.zfs = lib.mkForce false;

          # Build raw ext4 image
          image.repart = {
            name = "perfect-nixos";
            partitions = {
              "root" = {
                storePaths = [ config.system.build.toplevel ];
                repartConfig = {
                  Type = "root";
                  Format = "ext4";
                  Label = "nixos";
                  Minimize = "guess";
                };
              };
            };
          };
        })
      ];
    };

    # ===== Build targets =====
    packages.${system} = {
      vm = self.nixosConfigurations.vm.config.system.build.vm;
      mac-toplevel = self.nixosConfigurations.mac.config.system.build.toplevel;

      # Raw disk image for dd install from macOS
      disk-image = self.nixosConfigurations.diskImage.config.system.build.image;

      default = self.packages.${system}.vm;
    };
  };
}
