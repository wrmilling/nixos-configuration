# Icarus

Icarus is a 3 vCPU, 4GB ram, and 100GB SSD KVM from a random provider. The installation steps assume you have uploaded a nixos minimal iso image and booted the KVM instance into the iso environment and are connected to it via NoVNC.

## Installation

### Disk Setup

Creates 2 partitions on the drive, one for EFI Boot and one for the luks root.

```
$ sudo fdisk /dev/vda
> g (GPT Table)
> n (New Partition)
> <enter> (Default 1)
> <enter> (Default 2048)
> +500M
> t (Type)
> 1 (EFI)
> n (New Partition)
> <enter> (Default 2)
> <enter> (Default End of EFI)
> <enter> (Default End of Disk)
> w (Write)
$ sudo mkfs.fat -F 32 /dev/vda1
$ sudo fatlabel /dev/vda1 BOOTEFI
$ sudo mkfs.ext4 -L nixos /dev/vda2
$ sudo mount /dev/disk/by-label/nixos /mnt
$ sudo mkdir -p /mnt/boot
$ sudo mount /dev/disk/by-label/BOOTEFI /mnt/boot
```

### NixOS Install

Use a prepped nixos configuration to build the machine.

```
$ sudo nixos-generate-config --root /mnt
$ nix-shell -p vim wormhole-rs git git-crypt
$ cd /mnt/etc/nixos
$ sudo rm -rf ./*
$ sudo git clone https://github.com/wrmilling/nixos-configuration.git .
$ sudo wormhole-rs receive <CODE>
$ sudo mv KEY ../ && sudo git crypt unlock ../KEY && sudo rm ../KEY
$ sudo nixos-install --flake .#goku
```

## Outro

Good luck!