# NixOS Configuration

A work in progress, attempting to make it handle multiple machines and share between them.

## General Layout

Rough layout thoughts currently, still working on what feels natural. 

```
flake.nix (Entrypoint for rebuilding via nixos-rebuild or home-manager)
|-- home-manager (user level configuration per machine via home-manager)
  |-- features (Re-usable configurations for users in home-manager)
|-- machines (Definition of physical/virutal hosts)
  |-- common (Role definitions [Desktop, Laptop, Server])
    |-- addons (Optional configurations not used in a role)
    |-- modules (Shared configuration items used by the Roles)
  |-- donnager (Primary NixOS Laptop, Lenovo Legion Y530)
  |-- hermes (Oracle Cloud ARM64 instance)
  |-- serenity (Pinebook Pro Laptop)
```