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

    # ===== Build targets =====
    packages.${system} = {
      vm = self.nixosConfigurations.vm.config.system.build.vm;

      # Build the full system closure (for manual install)
      mac-toplevel = self.nixosConfigurations.mac.config.system.build.toplevel;

      default = self.packages.${system}.vm;
    };
  };
}
