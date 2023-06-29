# NixOS Configuration

A work in progress, attempting to make it handle multiple hosts and share between them.

## General Layout

Rough layout thoughts currently, still working on what feels natural. 

- [flake.nix](flake.nix) (Entrypoint for rebuilding via nixos-rebuild or home-manager)
  - [custom](custom/README.md) (Custom packages, modules, and overlays for my configuration)
    - [overlays](custom/overlays) (Custom overlays, primarily used for packages currently)
    - [pkgs](custom/pkgs) (Custom Packages, mainly items not yet in official nixpkgs) 
  - [home-manager](home-manager/README.md) (User level configuration per machine via home-manager)
    - [common](home-manager/common) (Re-usable configurations for users in home-manager)
    - [darwin](home-manager/darwin) (Specific home-manager configuration for darwin)
    - [donnager](home-manager/donnager) (Specific home-manager configuration for donnager)
    - [serenity](home-manager/serenity) (Specific home-manager configuration for serenity)
  - [hosts](hosts/README.md) - (Definition of physical/virutal hosts)
    - [common](hosts/common) (Role definitions [Desktop, Laptop, Server])
    - [darwin](hosts/darwin) (nix-darwin Laptop, Apple M1 Macbook Pro 16")
    - [donnager](hosts/donnager) (NixOS Laptop, Lenovo Legion Y530)
    - [hermes](hosts/hermes) (NixOS Server, Oracle ARM64)
    - [serenity](hosts/serenity) (NixOS Laptop, Pinebook Pro)

