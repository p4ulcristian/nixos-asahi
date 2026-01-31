{
  description = "Perfect NixOS - Same config for VM and M2 Mac";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-apple-silicon, caelestia-shell }:
  let
    system = "aarch64-linux";
  in {

    # ===== VM (for testing) =====
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit caelestia-shell system; };
      modules = [
        "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
        ./hardware-vm.nix    # VM hardware
        ./common.nix         # Shared config (identical to Mac)
      ];
    };

    # ===== Real M2 Mac (Asahi) =====
    nixosConfigurations.mac = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit caelestia-shell system; };
      modules = [
        nixos-apple-silicon.nixosModules.apple-silicon-support
        ./hardware-mac.nix   # Mac hardware (Asahi)
        ./common.nix         # Shared config (identical to VM)
      ];
    };

    # ===== Build targets =====
    packages.${system} = {
      # Test in VM
      vm = self.nixosConfigurations.vm.config.system.build.vm;
      default = self.packages.${system}.vm;

      # Build installer ISO for real Mac
      # installer = self.nixosConfigurations.mac.config.system.build.isoImage;
    };
  };
}
