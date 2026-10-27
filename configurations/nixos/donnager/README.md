# donnager

![neofetch screenshot](https://i.imgur.com/Hh16z3T.png)

Donnager is my Lenovo Legion Y530 with the 1050ti, these are the steps that I initially took to install NixOS, though once the config is setup it can just be reused for future re-installs if needed. This assumes you have booted into a NixOS install image from a USB stick, that we are installing with Full Disk Encryption, and that we will be using systemd-boot.

## Installation

### Disk Setup

Creates 2 partitions on the NVMe drive, one for EFI Boot and one for the luks encrypted root.

```
$ sudo fdisk /dev/nvme0n1
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
$ sudo mkfs.fat -F 32 /dev/nvme0n1p1
$ sudo fatlabel /dev/nvme0n1p1 BOOTEFI
$ sudo cryptsetup luksFormat /dev/nvme0n1p2
> YES
> <password>
> <password>
$ sudo cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
$ sudo mkfs.ext4 -L nixos /dev/mapper/cryptroot
$ sudo mount /dev/disk/by-label/nixos /mnt
$ sudo mkdir -p /mnt/boot
$ sudo mount /dev/disk/by-label/BOOTEFI /mnt/boot
```

### NixOS Install

Generate a config based on the currently detected hardware and disks.

```
$ sudo nixos-generate-config --root /mnt
```

Next I will normally open the hardware and configuration nix files to clean out comments and set basic information like hostname. Most of my other items are set by my modules so I will take care of those later.

Now, let's install:

```
$ cd /mnt
$ sudo nixos-install
> <root password when prompted>
$ sudo reboot
```

### First Run

Here is where I will normally try and setup all the hardware and enable the modules I want from this repo. Since I use the minimal install, I will kick things off like so:

```
$ nix-shell -p git git-crypt vim wormhole-rs
$ cd /etc/nixos
$ git clone https://github.com/wrmilling/nixos-configuration.git .
$ wormhole-rs receive <CODE>
$ mv KEY ../ && git crypt unlock ../KEY && rm ../KEY
```

The git-crypt key is sent from an existing machine with `wormhole-rs send`; `secrets/secrets.nix` must be unlocked for the flake to evaluate.

I will then move the generated config into a new host folder under `configurations/nixos/`, where the flake picks it up automatically as `nixosConfigurations.donnager`.

```
$ mkdir -p configurations/nixos/donnager
$ mv ../configuration.nix configurations/nixos/donnager/default.nix
$ mv ../hardware-configuration.nix configurations/nixos/donnager/hardware.nix
$ vim configurations/nixos/donnager/default.nix
# Import ./hardware.nix and enable the machineType/component modules as required.
```

I will then be able to update the nixos-configuration repo in github and just pull/rebuild as needed on the machine.

```
$ sudo nixos-rebuild switch --flake .#donnager
```

After the first switch, I clone the repo into my user's home, unlock git-crypt there the same way, and rebuild from it with [nh](https://github.com/nix-community/nh) from then on:

```
$ git clone https://github.com/wrmilling/nixos-configuration.git ~/.nixos-configuration
$ cd ~/.nixos-configuration
$ nix-shell -p wormhole-rs --run "wormhole-rs receive <CODE>"
$ mv KEY ../ && git crypt unlock ../KEY && rm ../KEY
```

Future rebuilds:

```
$ cd ~/.nixos-configuration
$ git pull
$ nh os switch .
$ nh home switch .
```

The above is aliased to `nhs` on my machines.

## Outro

Good luck!