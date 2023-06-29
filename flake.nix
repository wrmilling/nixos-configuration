{
  description = "WRMilling Nix Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware
    hardware.url = "github:nixos/nixos-hardware";

    # Darwin
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      secrets = import ./secrets.nix;
    in
    rec {
      # Custom Packages
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./custom/pkgs { inherit pkgs; }
      );

      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; }
      );

      # Overlays
      overlays = import ./custom/overlays { inherit inputs; };

      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      # nixosModules = import ./modules/nixos;

      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      # homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild switch --flake .#your-hostname'
      nixosConfigurations = {
        donnager = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs packages secrets; };
          modules = [
            ./hosts/donnager
          ];
        };
        hermes = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs packages secrets; };
          modules = [
            ./hosts/hermes
          ];
        };
        serenity = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs packages secrets; };
          modules = [
            ./hosts/serenity
          ];
        };
      };

      # nix-darwin configuration entrypoint
      # Available through 'darwin-rebuild switch --flake .#your-hostname'
      darwinConfigurations = {
        "${secrets.hosts.work-mac.hostname}" = darwin.lib.darwinSystem{
          system = "aarch64-darwin";
          specialArgs = { inherit inputs outputs packages secrets; };
          modules = [
            ./hosts/darwin
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager switch --flake .#your-username@your-hostname'
      homeConfigurations = {
        "${secrets.hosts.work-mac.username}@${secrets.hosts.work-mac.hostname}" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs secrets; };
          modules = [
            ./home-manager/darwin
          ];
        };
      };
    };
}
