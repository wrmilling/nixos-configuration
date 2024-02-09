# NixOS Configuration

A work in progress [NixOS]() configuration that can handle NixOS and nix-darwin on multiple hosts.

![neofetch screenshot](https://i.imgur.com/Hh16z3T.png)

## General Layout

- [flake.nix](flake.nix) (Entrypoint for rebuilding via nixos-rebuild or home-manager)
- [flake.lock](flake.lock) (Lockfile for current nix flake state)
- [custom](custom/README.md) (Custom packages, modules, and overlays for my configuration)
  - [overlays](custom/overlays) (Custom overlays, primarily used for packages currently)
  - [pkgs](custom/pkgs) (Custom Packages, mainly items not yet in official nixpkgs)
- [home-manager](home-manager/README.md) (User level configuration per machine via home-manager)
  - [common](home-manager/common) (Re-usable configurations for users in home-manager)
  - [darwin](home-manager/darwin) (Specific home-manager configuration for darwin)
  - [donnager](home-manager/donnager) (Specific home-manager configuration for donnager)
  - [riker](home-manager/riker) (Specific home-manager configuration for riker)
  - [serenity](home-manager/serenity) (Specific home-manager configuration for serenity)
  - [server](home-manager/server) (Basic home-manager configuration for generic servers)
- [hosts](hosts/README.md) - (Definition of physical/virutal hosts)
  - [bill](hosts/bill) (KVM Server, 1GB instance, testing)
  - [bob](hosts/bob) (OpenVZ Server, 128MB instance, testing)
  - [common](hosts/common) (Role definitions [Desktop, Laptop, Server])
  - [darwin](hosts/darwin) (nix-darwin Laptop, Apple M1 Macbook Pro 16")
  - [donnager](hosts/donnager) (NixOS Laptop, Lenovo Legion Y530)
  - [enterprise](hosts/enterprise) (NixOS Desktop, Custom Built)
  - [goku](hosts/goku) (NixOS Server, Oracle x86_64)
  - [hermes](hosts/hermes) (NixOS Server, Oracle ARM64)
  - [nk3s-amd64-0](hosts/nk3s-amd64-0) (NixOS Server, Virtual on NAS)
  - [nk3s-amd64-a](hosts/nk3s-amd64-a) (NixOS Server, Minisforum UN100C)
  - [nk3s-amd64-b](hosts/nk3s-amd64-b) (NixOS Server, Minisforum UN100C)
  - [nk3s-amd64-c](hosts/nk3s-amd64-c) (NixOS Server, Minisforum UN100C)
  - [nk3s-arm64-a](hosts/nk3s-arm64-a) (NixOS Server, Raspberry Pi 4 8GB)
  - [nk3s-arm64-b](hosts/nk3s-arm64-b) (NixOS Server, Raspberry Pi 4 8GB)
  - [nk3s-arm64-c](hosts/nk3s-arm64-c) (NixOS Server, Raspberry Pi 4 8GB)
  - [riker](hosts/riker) (NixOS Laptop, Pinebook Pro, Primary)
  - [serenity](hosts/serenity) (NixOS Laptop, Pinebook Pro, Broken Screen)
- [secrets](secrets) (Basic secrets, primarily git-crypt encrypted files)

## Credits

- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
- [samueldr/nixos-configuration](https://gitlab.com/samueldr/nixos-configuration)
- [billimek/nix-config](https://github.com/billimek/nix-config)
