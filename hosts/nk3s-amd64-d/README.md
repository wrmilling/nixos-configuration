# nk3s-amd64-d

nk3s-amd64-d is a BMAX B4 Plus mini-pc with a 4-core Intel N100 CPU, 16GB ram, 512GB M.2 SATA SSD boot, and a 1TB 2.5" SSD for Ceph. This machine is used as a K3S worker node in my Homelab cluster.

## Installation

### Disk Setup

Create 2 partitions on the M.2 SATA SSD, one for EFI Boot and one for the root. `/dev/sda` is assumed based on initial install testing.

```
$ sudo fdisk /dev/sda
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
$ sudo mkfs.fat -F 32 /dev/sda1
$ sudo fatlabel /dev/sda1 BOOTEFI
$ sudo mkfs.ext4 -L nixos /dev/sda2
$ sudo mount /dev/disk/by-label/nixos /mnt
$ sudo mkdir -p /mnt/boot
$ sudo mount /dev/disk/by-label/BOOTEFI /mnt/boot
```

### NixOS Install

The steps below assume the configuration is already done for this machine and you are just installing from scratch:

```
$ sudo su -
$ cd /mnt
$ mkdir -p etc/nixos
$ cd etc/nixos
$ nix-shell -p git git-crypt magic-wormhole vim
$ git clone https://github.com/wrmilling/nixos-configuration.git .
$ <Unlock git-crypt using static key, can be transferred from existing install with magic wormhole>
$ nixos-install --flake .#nk3s-amd64-d
$ shutdown -r now
```

## Outro

Good luck!