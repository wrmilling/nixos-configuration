# Hosts

Main system level NixOS configuration for my hosts, still in progress for sifting through the config to separate machine-level concerns from user-level concerns (latter being moved to home manager).

Each machine has its own directory where main config and hardware specific to it can be defined. There is also a [common](common) directory where profiles (Laptop, Desktop, Server), modules (Used by profiles to define system level setup), and optional modules (extra use cases not in a default profile) are defined.

These configurations generally reference a [home-manager](../home-manager) config to add in user-level packages and dotfiles configuration.

##  Configurations

- [bob](bob) (Server, OpenVZ Test-instance)
- [darwin](darwin) (Laptop, M1 Macbook Pro)
- [donnager](donnager) (Laptop, Lenovo Legion Y530)
- [hermes](hermes) (Server, Oracle Free-tier ARM)
- [riker](riker) (Laptop, Pine64 Pinebook Pro, Cracked Screen)
- [serenity](serenity) (Laptop, Pine64 Pinebook Pro)