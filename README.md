# NixOS Configuration

[Nix / NixOS](https://nixos.org/) configuration repo that handles NixOS, nix-darwin, and home-manager configurations.

![fastfetch screenshot](https://i.imgur.com/EwKciVY.png)

## General Layout

- [flake.nix](flake.nix) (Entrypoint for rebuilding via `nh os|darwin|home switch .`)
- [flake.lock](flake.lock) (Lockfile for current nix flake state)
- [configurations/darwin](configurations/darwin/README.md) - (Definition of mac-based hosts)
  - [work](configurations/darwin/work) (Laptop, Apple M1 Macbook Pro 16")
- [configurations/home](configurations/home/README.md) (User level configuration per machine via home-manager)
  - [personal](configurations/home/personal) (Personal/home-specific configuration)
  - [pinebook](configurations/home/pinebook) (Pinebook-specific configuration)
  - [server](configurations/home/server) (Basic home-manager configuration for generic servers)
  - [work](configurations/home/work) (MacOS-specific configuration)
- [configurations/nixos](configurations/nixos/README.md) - (Definition of physical/virtual hosts)
  - [agent-sandbox](configurations/nixos/agent-sandbox) (MicroVM sandbox host; `agent-sandbox-aarch64` reuses its guest config for aarch64)
  - [bart](configurations/nixos/bart) (Server, 4GB KVM Instance)
  - [bender](configurations/nixos/bender) (Laptop, Apple Macbook Pro)
  - [bob](configurations/nixos/bob) (Server, Oracle Free-tier ARM64)
  - [donnager](configurations/nixos/donnager) (Laptop, Lenovo Legion Y530)
  - [enterprise](configurations/nixos/enterprise) (Desktop, Custom Built)
  - [goku](configurations/nixos/goku) (Server, 4GB KVM Instance)
  - [icarus](configurations/nixos/icarus) (Laptop, HP EliteBook 845 G8)
  - [isaac](configurations/nixos/isaac) (Server, rPi4 8GB)
  - [jack](configurations/nixos/jack) (Server, rPi4 8GB)
  - [khan](configurations/nixos/khan) (Server, Oracle Free-tier x86_64)
  - [linus](configurations/nixos/linus) (Server, 2GB KVM Instance)
  - [loki](configurations/nixos/loki) (Desktop, Lenovo ThinkCentre M715q)
  - [nk3s-amd64-0](configurations/nixos/nk3s-amd64-0) (Server, Virtual on NAS)
  - [nk3s-amd64-a](configurations/nixos/nk3s-amd64-a) (Server, Minisforum UN100C)
  - [nk3s-amd64-b](configurations/nixos/nk3s-amd64-b) (Server, Minisforum UN100C)
  - [nk3s-amd64-c](configurations/nixos/nk3s-amd64-c) (Server, Minisforum UN100C)
  - [nk3s-amd64-d](configurations/nixos/nk3s-amd64-d) (Server, BMAX B4 Plus)
  - [owen](configurations/nixos/owen) (Server, rPi4 8GB)
  - [retired](configurations/nixos/retired) (Retired Configurations)
  - [riker](configurations/nixos/riker) (Laptop, Pinebook Pro, Primary)
  - [serenity](configurations/nixos/serenity) (Laptop, Pinebook Pro, Broken Screen)
- [custom](custom/README.md) (Custom packages and overlays for my configuration)
  - [overlays](custom/overlays) (Custom overlays, primarily used for packages currently)
  - [pkgs](custom/pkgs) (Custom Packages, mainly items not yet in official nixpkgs)
- [lib](lib) (Shared Nix helpers, e.g. module autowiring and agent-sandbox helpers)
- [modules](modules) (NixOS, nix-darwin, and Home Manager reusable modules)
- [secrets](secrets/README.md) (sops-nix encrypted secrets plus git-crypt encrypted values)

## Credits

- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
- [samueldr/nixos-configuration](https://gitlab.com/samueldr/nixos-configuration)
- [billimek/nix-config](https://github.com/billimek/nix-config)
