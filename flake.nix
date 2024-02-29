{
  description = "WRMilling Nix Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    # Testing out POP_OS' COSMIC DE/WM
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    nixos-cosmic.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware
    hardware.url = "github:nixos/nixos-hardware";

    # Darwin
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    darwin,
    nixos-cosmic,
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

    secrets = import ./secrets/secrets.nix;

    mkNixos = modules:
      nixpkgs.lib.nixosSystem {
        inherit modules;
        specialArgs = {inherit inputs outputs secrets;};
      };

    mkDarwin = system: modules:
      darwin.lib.darwinSystem {
        inherit modules;
        system = system;
        specialArgs = {inherit inputs outputs secrets;};
      };

    mkHome = pkgs: modules:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs modules;
        extraSpecialArgs = {inherit inputs outputs secrets;};
      };
  in rec {
    # Custom Packages
    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        import ./custom/pkgs {inherit pkgs;}
    );

    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Devshell for bootstrapping
    # Acessible through 'nix develop' or 'nix-shell' (legacy)
    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        import ./shell.nix {inherit pkgs;}
    );

    # Overlays
    overlays = import ./custom/overlays {inherit inputs;};

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild switch --flake .#your-hostname'
    nixosConfigurations = {
      # Desktop/Laptop
      donnager = mkNixos [
        {
          nix.settings = {
            substituters = [ "https://cosmic.cachix.org/" ];
            trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
          };
        }
        nixos-cosmic.nixosModules.default
        ./hosts/donnager
      ];
      enterprise = mkNixos [./hosts/enterprise];
      riker = mkNixos [./hosts/riker];
      serenity = mkNixos [./hosts/serenity];

      # Servers
      bill = mkNixos [./hosts/bill];
      bob = mkNixos [./hosts/bob];
      goku = mkNixos [./hosts/goku];
      hermes = mkNixos [./hosts/hermes];

      # k3s Hosts
      nk3s-amd64-0 = mkNixos [./hosts/nk3s-amd64-0];
      nk3s-amd64-a = mkNixos [./hosts/nk3s-amd64-a];
      nk3s-amd64-b = mkNixos [./hosts/nk3s-amd64-b];
      nk3s-amd64-c = mkNixos [./hosts/nk3s-amd64-c];
      nk3s-arm64-a = mkNixos [./hosts/nk3s-arm64-a];
      nk3s-arm64-b = mkNixos [./hosts/nk3s-arm64-b];
      nk3s-arm64-c = mkNixos [./hosts/nk3s-arm64-c];
    };

    # nix-darwin configuration entrypoint
    # Available through 'darwin-rebuild switch --flake .#your-hostname'
    darwinConfigurations = {
      "${secrets.hosts.work-mac.hostname}" =
        mkDarwin "aarch64-darwin" [./hosts/darwin];
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager switch --flake .#your-username@your-hostname'
    homeConfigurations = {
      "${secrets.hosts.work-mac.username}@${secrets.hosts.work-mac.hostname}" =
        mkHome nixpkgs.legacyPackages.aarch64-darwin [./home-manager/darwin];
    };
  };
}
