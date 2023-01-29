# Installing NixOS on Donnager

Donnager is my Lenovo Legion Y530 with the 1050ti, these are the steps that I initially took to install NixOS, though once the config is setup it can just be re-used for future re-installs if needed. This assumes you have booted into a NixOS install image from a USB stick, that we are installing with Full Disk Encryption, and that we will be using systemd-boot. 

## Disk Setup

Creates 2 partitions on the NVMe drive, one for EFI Boot and one for the luks encrypted root. 

```
sudo fdisk /dev/nvme0n1
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
sudo mkfs.fat -F 32 /dev/nvme0n1p1
sudo fatlabel /dev/nvm0n1p1 BOOTEFI
sudo cryptsetup luksFormat /dev/nvm0n1p2
> YES
> <password>
> <password>
sudo cryptsetup luksOpen /dev/nvm0n1p2 cryptroot
sudo mkfs.ext4 -L nixos /dev/mapper/cryptroot
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/BOOTEFI /mnt/boot
```

## NixOS Install

Generate a config based on the currently detected hardware and disks. 

```
sudo nixos-generate-config --root /mnt
```

I then opened the config to clean out comments and ensure the options I wanted were in place, the initial edits looked like this: 

```
<Copy File When Ready>
```

Then I did a little cleanup in the hardware-configuration as well: 

```
<Copy File When Ready>
```

Now, lets install: 

```
cd /mnt
sudo nixos-install
> <root password when prompted>
sudo reboot
```

## First Run

Here is where I will normally try and setup all the hardware and import the profiles/modules I want from this repo. Since I use the minimal install, I will kick things off like so: 

```
nix-shell -p git vim
```