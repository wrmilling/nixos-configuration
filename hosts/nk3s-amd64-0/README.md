# nk3s-amd64-0

nk3s-amd64-0 is a QEMU virtual machine on my NAS host running TrueNAS. It is operating as the master node for my homelab k3s cluster. The installation steps below assumes you have a bridge on your network properly setup so that the VM can get an IP on the local network.

## Installation

### Disk Setup

Creates 2 partitions on the virtio drive, one for EFI Boot and one for the root.

```
$ sudo fdisk /dev/vma
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
$ sudo mkfs.fat -F 32 /dev/vma1
$ sudo fatlabel /dev/vma1 BOOTEFI
$ sudo mkfs.ext4 -L nixos /dev/mapper/vma2
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
$ git clone https://git.sr.ht/~wrmilling/nixos-configuration .
$ <Unlock git-crypt using static key, can be transferred from existing install with magic wormhole>
$ nixos-install --flake .#nk3s-amd64-0
$ shutdown -r now
```

## Outro

Good luck!