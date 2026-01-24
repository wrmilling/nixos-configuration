{
  description = "WRMilling Nix Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # Hardware
    hardware.url = "github:NixOS/nixos-hardware";

    # Home-Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Darwin
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Jovian (Steam Deck)
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS/development";
    jovian.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets through sops
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # WSL
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # Lanzaboote for SecureBoot
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    # OpenCode Coding Agent
    opencode-src.url = "github:anomalyco/opencode/dev";
    opencode-src.inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      darwin,
      nixos-wsl,
      lanzaboote,
      opencode-src,
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

      # autowire modules
      lib = nixpkgs.lib;
      autowire = import ./lib/autowire.nix { inherit lib; };
      root = ./.;
      nixosModules = autowire.discoverModules { dir = root + /modules/nixos; };
      darwinModules = autowire.discoverModules { dir = root + /modules/darwin; };
      homeModules = autowire.discoverModules { dir = root + /modules/home; };

      mkNixos =
        modules:
        nixpkgs.lib.nixosSystem {
          modules = modules ++ [
            sops-nix.nixosModules.sops
            lanzaboote.nixosModules.lanzaboote
            { imports = builtins.attrValues nixosModules; }
          ];
          specialArgs = {
            inherit inputs outputs secrets;
          };
        };

      mkDarwin =
        system: modules:
        darwin.lib.darwinSystem {
          modules = modules ++ [
            { imports = builtins.attrValues darwinModules; }
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
            # sops-nix.nixosModules.sops
            { imports = builtins.attrValues homeModules; }
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
        bender = mkNixos [ ./configurations/nixos/bender ];
        cousteau = mkNixos [
          ./configurations/nixos/cousteau
          nixos-wsl.nixosModules.default
        ];
        donnager = mkNixos [ ./configurations/nixos/donnager ];
        enterprise = mkNixos [ ./configurations/nixos/enterprise ];
        icarus = mkNixos [ ./configurations/nixos/icarus ];
        loki = mkNixos [ ./configurations/nixos/loki ];
        riker = mkNixos [ ./configurations/nixos/riker ];
        serenity = mkNixos [ ./configurations/nixos/serenity ];

        # Servers
        bart = mkNixos [ ./configurations/nixos/bart ];
        bob = mkNixos [ ./configurations/nixos/bob ];
        goku = mkNixos [ ./configurations/nixos/goku ];
        isaac = mkNixos [ ./configurations/nixos/isaac ];
        jack = mkNixos [ ./configurations/nixos/jack ];
        khan = mkNixos [ ./configurations/nixos/khan ];
        linus = mkNixos [ ./configurations/nixos/linus ];
        owen = mkNixos [ ./configurations/nixos/owen ];

        # k3s Hosts
        nk3s-amd64-0 = mkNixos [ ./configurations/nixos/nk3s-amd64-0 ];
        nk3s-amd64-a = mkNixos [ ./configurations/nixos/nk3s-amd64-a ];
        nk3s-amd64-b = mkNixos [ ./configurations/nixos/nk3s-amd64-b ];
        nk3s-amd64-c = mkNixos [ ./configurations/nixos/nk3s-amd64-c ];
        nk3s-amd64-d = mkNixos [ ./configurations/nixos/nk3s-amd64-d ];
      };

      # nix-darwin configuration entrypoint
      # Available through 'darwin-rebuild switch --flake .#your-hostname'
      darwinConfigurations = {
        "${secrets.hosts.work-mac.hostname}" = mkDarwin "aarch64-darwin" [ ./configurations/darwin/work ];
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager switch --flake .#your-username@your-hostname'
      homeConfigurations = {
        "${secrets.hosts.work-mac.username}@${secrets.hosts.work-mac.hostname}" =
          mkHome nixpkgs.legacyPackages.aarch64-darwin
            [ ./configurations/home/work ];

        # TODO: Replace with an autowired version which can discover the system type and usernames

        # Desktop / Laptop
        "w4cbe@bender" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/personal ];
        "w4cbe@cousteau" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/personal ];
        "w4cbe@donnager" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/personal ];
        "w4cbe@icarus" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/personal ];
        "w4cbe@enterprise" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/personal ];
        "w4cbe@loki" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/personal ];
        "w4cbe@riker" = mkHome nixpkgs.legacyPackages.aarch64-linux [ ./configurations/home/pinebook ];
        "w4cbe@serenity" = mkHome nixpkgs.legacyPackages.aarch64-linux [ ./configurations/home/pinebook ];

        # Servers
        "w4cbe@bart" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
        "w4cbe@bob" = mkHome nixpkgs.legacyPackages.aarch64-linux [ ./configurations/home/server];
        "w4cbe@goku" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
        "w4cbe@isaac" = mkHome nixpkgs.legacyPackages.aarch64-linux [ ./configurations/home/server ];
        "w4cbe@jack" = mkHome nixpkgs.legacyPackages.aarch64-linux [ ./configurations/home/server ];
        "w4cbe@khan" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
        "w4cbe@linus" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
        "w4cbe@owen" = mkHome nixpkgs.legacyPackages.aarch64-linux [ ./configurations/home/server ];

        # K3s hosts
        "w4cbe@nk3s-amd64-0" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
        "w4cbe@nk3s-amd64-a" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
        "w4cbe@nk3s-amd64-b" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
        "w4cbe@nk3s-amd64-c" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
        "w4cbe@nk3s-amd64-d" = mkHome nixpkgs.legacyPackages.x86_64-linux [ ./configurations/home/server ];
      };
    };
}
