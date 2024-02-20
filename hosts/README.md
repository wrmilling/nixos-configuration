# Hosts

Main system level NixOS configuration for my hosts, still in progress for sifting through the config to separate machine-level concerns from user-level concerns (latter being moved to home manager).

Each machine has its own directory where main config and hardware specific to it can be defined. There is also a [common](common) directory where profiles (Laptop, Desktop, Server), modules (Used by profiles to define system level setup), and optional modules (extra use cases not in a default profile) are defined.

These configurations generally reference a [home-manager](../home-manager) config to add in user-level packages and dotfiles configuration.

##  Configurations

- [bill](bill) (Server, KVM Test-instance)
- [bob](bob) (Server, Oracle Free-tier ARM64)
- [darwin](darwin) (Laptop, M1 Macbook Pro)
- [donnager](donnager) (Laptop, Lenovo Legion Y530)
- [enterprise](enterprise) (Desktop, Custom Built)
- [goku](goku) (Server, Oracle Free-tier x86_64)
- [luke](luke) (Server, OpenVZ Test-instance)
- [nk3s-amd64-0](nk3s-amd64-0) (Server, Virtual on NAS)
- [nk3s-amd64-a](nk3s-amd64-a) (Server, Minisforum UN100C)
- [nk3s-amd64-b](nk3s-amd64-b) (Server, Minisforum UN100C)
- [nk3s-amd64-c](nk3s-amd64-c) (Server, Minisforum UN100C)
- [nk3s-arm64-a](nk3s-arm64-a) (Server, Raspberry Pi 4 8GB)
- [nk3s-arm64-b](nk3s-arm64-b) (Server, Raspberry Pi 4 8GB)
- [nk3s-arm64-c](nk3s-arm64-c) (Server, Raspberry Pi 4 8GB)
- [riker](riker) (Laptop, Pine64 Pinebook Pro, Cracked Screen)
- [serenity](serenity) (Laptop, Pine64 Pinebook Pro)