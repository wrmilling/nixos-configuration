# Hosts

Main system level Darwin configuration for my hosts, still in progress for sifting through the config to separate machine-level concerns from user-level concerns (latter being moved to home manager).

Each machine has its own directory where main config and hardware specific to it can be defined. These configurations generally reference a [home-manager](../home-manager) config to add in user-level packages and dotfiles configuration.

##  Configurations

- [work](work) (Laptop, M1 Macbook Pro via nix-darwin)