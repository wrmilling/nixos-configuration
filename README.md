# NixOS Configuration

A work in progress [NixOS](https://nixos.org/) configuration that can handle NixOS and nix-darwin on multiple hosts.

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
  - [haley](home-manager/haley) (User specific home manager configuration to be re-used in multiple hosts)
  - [riker](home-manager/riker) (Machine specific home-manager configuration for riker)
  - [serenity](home-manager/serenity) (Machine specific home-manager configuration for serenity)
  - [server](home-manager/server) (Basic home-manager configuration for generic servers)
  - [w4cbe](home-manager/w4cbe) (User specific home manager configuration to be re-used in multiple hosts)
- [hosts](hosts/README.md) - (Definition of physical/virutal hosts)
  - [bart](hosts/bart) (Server, 2GB KVM Instance)
  - [bob](hosts/bob) (Server, Oracle ARM64)
  - [common](hosts/common) (Role definitions [Desktop, Laptop, Server])
  - [cousteau](cousteau) (WSL, Windows 11)
  - [darwin](hosts/darwin) (Laptop, Apple M1 Macbook Pro 16")
  - [donnager](hosts/donnager) (Laptop, Lenovo Legion Y530)
  - [enterprise](hosts/enterprise) (Desktop, Custom Built)
  - [goku](hosts/goku) (Server, 4GB KVM Instance)
  - [icarus](hosts/icarus) (Laptop, HP EliteBook 845 G8)
  - [isaac](hosts/isaac) (Server, rPi4 8GB)
  - [jack](hosts/jack) (Server, rPi4 8GB)
  - [khan](hosts/khan) (Server, Oracle x86_64)
  - [linus](hosts/linus) (Server, 2GB KVM Instance)
  - [nk3s-amd64-0](hosts/nk3s-amd64-0) (Server, Virtual on NAS)
  - [nk3s-amd64-a](hosts/nk3s-amd64-a) (Server, Minisforum UN100C)
  - [nk3s-amd64-b](hosts/nk3s-amd64-b) (Server, Minisforum UN100C)
  - [nk3s-amd64-c](hosts/nk3s-amd64-c) (Server, Minisforum UN100C)
  - [nk3s-amd64-d](hosts/nk3s-amd64-d) (Server, BMAX B4 Plus)
  - [owen](hosts/owen) (Server, rPi4 8GB)
  - [retired](hosts/retired) (Retired Configurations)
  - [riker](hosts/riker) (NixOS Laptop, Pinebook Pro, Primary)
  - [serenity](hosts/serenity) (NixOS Laptop, Pinebook Pro, Broken Screen)
- [secrets](secrets) (Basic secrets, primarily git-crypt encrypted files)

## Credits

- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
- [samueldr/nixos-configuration](https://gitlab.com/samueldr/nixos-configuration)
- [billimek/nix-config](https://github.com/billimek/nix-config)
