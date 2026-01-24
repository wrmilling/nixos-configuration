# Hosts

Main system level NixOS configuration for my hosts, still in progress for sifting through the config to separate machine-level concerns from user-level concerns (latter being moved to home manager).

Each machine has its own directory where main config and hardware specific to it can be defined. These configurations generally reference a [home-manager](../home-manager) config to add in user-level packages and dotfiles configuration.

##  Configurations

- [bart](bart) (Server, KVM 2GB Instance)
- [bob](bob) (Server, Oracle Free-tier ARM64)
- [donnager](donnager) (Laptop, Lenovo Legion Y530)
- [enterprise](enterprise) (Desktop, Custom Built)
- [goku](goku) (Server, KVM 4GB Instance)
- [icarus](icarus) (Laptop, HP EliteBook 845 G8)
- [isaac](isaac) (Server, rPi4 8GB)
- [jack](jack) (Server, rPi4 8GB)
- [khan](khan) (Server, Oracle Free-tier x86_64)
- [linus](linus) (Server, KVM 2GB Instance)
- [loki](loki) (Laptop, Lenovo ThinkCentre M715q)
- [nk3s-amd64-0](nk3s-amd64-0) (Server, Virtual on NAS)
- [nk3s-amd64-a](nk3s-amd64-a) (Server, Minisforum UN100C)
- [nk3s-amd64-b](nk3s-amd64-b) (Server, Minisforum UN100C)
- [nk3s-amd64-c](nk3s-amd64-c) (Server, Minisforum UN100C)
- [nk3s-amd64-d](nk3s-amd64-d) (Server, BMAX B4 Plus)
- [owen](owen) (Server, rPi4 8GB)
- [retired](retired) (Retired Configurations)
- [riker](riker) (Laptop, Pinebook Pro)
- [serenity](serenity) (Laptop, Pinebook Pro)