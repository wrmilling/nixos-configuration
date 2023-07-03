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

    # sops-nix
    sops-nix.url = "github:wrmilling/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    darwin,
    sops-nix,
    ...
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    secrets = import ./secrets/obscurity.nix;

    mkNixos = modules: nixpkgs.lib.nixosSystem {
      inherit modules;
      specialArgs = { inherit inputs outputs secrets; };
    };

    mkDarwin = system: modules: darwin.lib.darwinSystem{
      inherit modules;
      system = system;
      specialArgs = { inherit inputs outputs secrets; };
    };

    mkHome = pkgs: modules: home-manager.lib.homeManagerConfiguration {
      inherit pkgs modules;
      extraSpecialArgs = { inherit inputs outputs secrets; };
    };
  in rec {
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

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild switch --flake .#your-hostname'
    nixosConfigurations = {
      donnager = mkNixos [ ./hosts/donnager ];
      hermes = mkNixos [ ./hosts/hermes ];
      serenity = mkNixos [ ./hosts/serenity ];
      bob = mkNixos [ ./hosts/bob ];
    };

    # nix-darwin configuration entrypoint
    # Available through 'darwin-rebuild switch --flake .#your-hostname'
    darwinConfigurations = {
      "${secrets.hosts.work-mac.hostname}" =
        mkDarwin "aarch64-darwin" [ ./hosts/darwin ];
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager switch --flake .#your-username@your-hostname'
    homeConfigurations = {
      "${secrets.hosts.work-mac.username}@${secrets.hosts.work-mac.hostname}" =
        mkHome nixpkgs.legacyPackages.aarch64-darwin [ ./home-manager/darwin ];
    };
  };
}
