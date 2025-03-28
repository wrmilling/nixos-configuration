{
  description = "WRMilling Nix Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware
    hardware.url = "github:wrmilling/nixos-hardware/lenovo-y530-15ICH";

    # Darwin
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Jovian (Steam Deck)
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS/development";
    jovian.inputs.nixpkgs.follows = "nixpkgs";

    # Lix, like nix
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0-3.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lix-module,
      home-manager,
      darwin,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      secrets = import ./secrets/secrets.nix;

      mkNixos =
        modules:
        nixpkgs.lib.nixosSystem {
          modules = modules ++ [
            lix-module.nixosModules.default
          ];
          specialArgs = {
            inherit inputs outputs secrets;
          };
        };

      mkDarwin =
        system: modules:
        darwin.lib.darwinSystem {
          modules = modules ++ [
            lix-module.nixosModules.default
          ];
          system = system;
          specialArgs = {
            inherit inputs outputs secrets;
          };
        };

      mkHome =
        pkgs: modules:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = modules ++ [
            lix-module.nixosModules.default
          ];
          extraSpecialArgs = {
            inherit inputs outputs secrets;
          };
        };
    in
    rec {
      # Custom Packages
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./custom/pkgs { inherit pkgs; }
      );

      # Formatter for your nix files, available through 'nix fmt'
      # Other options beside 'alejandra' include 'nixpkgs-fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      # Overlays
      overlays = import ./custom/overlays { inherit inputs; };

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild switch --flake .#your-hostname'
      nixosConfigurations = {
        # Desktop/Laptop
        bender = mkNixos [ ./hosts/bender ];
        donnager = mkNixos [ ./hosts/donnager ];
        enterprise = mkNixos [ ./hosts/enterprise ];
        riker = mkNixos [ ./hosts/riker ];
        serenity = mkNixos [ ./hosts/serenity ];

        # Servers
        bart = mkNixos [ ./hosts/bart ];
        bob = mkNixos [ ./hosts/bob ];
        goku = mkNixos [ ./hosts/goku ];

        # k3s Hosts
        nk3s-amd64-0 = mkNixos [ ./hosts/nk3s-amd64-0 ];
        nk3s-amd64-a = mkNixos [ ./hosts/nk3s-amd64-a ];
        nk3s-amd64-b = mkNixos [ ./hosts/nk3s-amd64-b ];
        nk3s-amd64-c = mkNixos [ ./hosts/nk3s-amd64-c ];
        nk3s-amd64-d = mkNixos [ ./hosts/nk3s-amd64-d ];
      };

      # nix-darwin configuration entrypoint
      # Available through 'darwin-rebuild switch --flake .#your-hostname'
      darwinConfigurations = {
        "${secrets.hosts.work-mac.hostname}" = mkDarwin "aarch64-darwin" [ ./hosts/darwin ];
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager switch --flake .#your-username@your-hostname'
      homeConfigurations = {
        "${secrets.hosts.work-mac.username}@${secrets.hosts.work-mac.hostname}" =
          mkHome nixpkgs.legacyPackages.aarch64-darwin
            [ ./home-manager/darwin ];
      };
    };
}
