{
  description = "WRMilling Nix Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Hardware
    hardware.url = "github:wrmilling/nixos-hardware/lenovo-y530-15ICH";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Jovian (Steam Deck)
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS/development";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secrets through sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      darwin,
      nixos-wsl,
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
        "riscv64-linux"
      ];

      secrets = import ./secrets/secrets.nix;

      mkNixos =
        modules:
        nixpkgs.lib.nixosSystem {
          modules = modules ++ [
            sops-nix.nixosModules.sops
          ];
          specialArgs = {
            inherit inputs outputs secrets;
          };
        };

      mkDarwin =
        system: modules:
        darwin.lib.darwinSystem {
          modules = modules ++ [ ];
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
            # sops-nix.nixosModules.sops
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
        cousteau = mkNixos [
          ./hosts/cousteau
          nixos-wsl.nixosModules.default
        ];
        donnager = mkNixos [ ./hosts/donnager ];
        enterprise = mkNixos [ ./hosts/enterprise ];
        riker = mkNixos [ ./hosts/riker ];
        serenity = mkNixos [ ./hosts/serenity ];

        # Servers
        bart = mkNixos [ ./hosts/bart ];
        bob = mkNixos [ ./hosts/bob ];
        goku = mkNixos [ ./hosts/goku ];
        linus = mkNixos [ ./hosts/linus ];

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
