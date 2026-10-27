# bender

Bender

## Installation

### Disk Setup

Creates 2 partitions on the NVMe drive, one for EFI Boot and one for the luks encrypted root.

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
$ sudo cryptsetup luksFormat /dev/sda2
> YES
> <password>
> <password>
$ sudo cryptsetup luksOpen /dev/sda2 cryptroot
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
$ nix-shell -p git vim
$ cd /etc/nixos
$ git clone https://github.com/wrmilling/nixos-configuration.git .
```

I will then move the generated config into a new host folder under `configurations/nixos/`, where the flake picks it up automatically as `nixosConfigurations.bender`.

```
$ mkdir -p configurations/nixos/bender
$ mv ../configuration.nix configurations/nixos/bender/default.nix
$ mv ../hardware-configuration.nix configurations/nixos/bender/hardware.nix
$ vim configurations/nixos/bender/default.nix
# Import ./hardware.nix and enable the machineType/component modules as required.
```

I will then be able to update the nixos-configuration repo in github and just pull/rebuild as needed on the machine.

```
$ sudo nixos-rebuild switch --flake .#bender
```

After the first switch, I keep the repo at `~/.nixos-configuration` and rebuild with [nh](https://github.com/nix-community/nh):

```
$ cd ~/.nixos-configuration
$ git pull
$ nh os switch .
$ nh home switch .
```

The above is aliased to `nhs` on my machines.

## Outro

Good luck!