# NixOS Configuration

A work in progress [NixOS](https://nixos.org/) configuration that can handle NixOS and nix-darwin on multiple hosts.

![neofetch screenshot](https://i.imgur.com/Hh16z3T.png)

## General Layout

- [flake.nix](flake.nix) (Entrypoint for rebuilding via nixos-rebuild or home-manager)
- [flake.lock](flake.lock) (Lockfile for current nix flake state)
- [configurations/darwin](configurations/darwin/README.md) - (Definition of mac-based hosts)
  - [work](configurations/nixos/work) (Laptop, Apple M1 Macbook Pro 16")
- [configurations/home](configurations/home/README.md) (User level configuration per machine via home-manager)
  - [common](configurations/home/common) (Re-usable configurations for users in home-manager, to be migrated)
  - [darwin](configurations/home/darwin) (Specific home-manager configuration for darwin)
  - [haley](configurations/home/haley) (User specific home manager configuration to be re-used in multiple hosts)
  - [riker](configurations/home/riker) (Machine specific home-manager configuration for riker)
  - [serenity](configurations/home/serenity) (Machine specific home-manager configuration for serenity)
  - [server](configurations/home/server) (Basic home-manager configuration for generic servers)
  - [w4cbe](configurations/home/w4cbe) (User specific home manager configuration to be re-used in multiple hosts)
- [configurations/nixos](configurations/nixos/README.md) - (Definition of physical/virutal hosts)
  - [bart](configurations/nixos/bart) (Server, 2GB KVM Instance)
  - [bob](configurations/nixos/bob) (Server, Oracle ARM64)
  - [cousteau](configurations/nixos/cousteau) (WSL, Windows 11)
  - [donnager](configurations/nixos/donnager) (Laptop, Lenovo Legion Y530)
  - [enterprise](configurations/nixos/enterprise) (Desktop, Custom Built)
  - [goku](configurations/nixos/goku) (Server, 4GB KVM Instance)
  - [icarus](configurations/nixos/icarus) (Laptop, HP EliteBook 845 G8)
  - [isaac](configurations/nixos/isaac) (Server, rPi4 8GB)
  - [jack](configurations/nixos/jack) (Server, rPi4 8GB)
  - [khan](configurations/nixos/khan) (Server, Oracle x86_64)
  - [linus](configurations/nixos/linus) (Server, 2GB KVM Instance)
  - [nk3s-amd64-0](configurations/nixos/nk3s-amd64-0) (Server, Virtual on NAS)
  - [nk3s-amd64-a](configurations/nixos/nk3s-amd64-a) (Server, Minisforum UN100C)
  - [nk3s-amd64-b](configurations/nixos/nk3s-amd64-b) (Server, Minisforum UN100C)
  - [nk3s-amd64-c](configurations/nixos/nk3s-amd64-c) (Server, Minisforum UN100C)
  - [nk3s-amd64-d](configurations/nixos/nk3s-amd64-d) (Server, BMAX B4 Plus)
  - [owen](configurations/nixos/owen) (Server, rPi4 8GB)
  - [retired](configurations/nixos/retired) (Retired Configurations)
  - [riker](configurations/nixos/riker) (NixOS Laptop, Pinebook Pro, Primary)
  - [serenity](configurations/nixos/serenity) (NixOS Laptop, Pinebook Pro, Broken Screen)
- [custom](custom/README.md) (Custom packages, modules, and overlays for my configuration)
  - [overlays](custom/overlays) (Custom overlays, primarily used for packages currently)
  - [pkgs](custom/pkgs) (Custom Packages, mainly items not yet in official nixpkgs)
- [modules](modules) (NixOS and Home Manager re-usable modules)
- [secrets](secrets) (Basic secrets, primarily git-crypt encrypted files)

## Credits

- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
- [samueldr/nixos-configuration](https://gitlab.com/samueldr/nixos-configuration)
- [billimek/nix-config](https://github.com/billimek/nix-config)
