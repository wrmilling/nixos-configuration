# Bart

Bart is a 3 vCPU, 4GB ram, and 100GB SSD KVM from a random provider. The installation steps assume you have uploaded a nixos minimal iso image and booted the KVM instance into the iso environment and are connected to it via NoVNC.

## Installation

### Disk Setup

Creates 2 partitions on the drive, one for EFI Boot and one for the luks root.

```
$ sudo fdisk /dev/vda
> o (MBR Table)
> n (New Partition)
> <enter> (Default 1)
> <enter> (Default 2048)
> <enter> (Default End of Disk)
> w (Write)
$ sudo mkfs.ext4 -L nixos /dev/vda1
$ sudo mount /dev/disk/by-label/nixos /mnt
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
$ sudo nixos-install --flake .#bart
```

## Outro

Good luck!