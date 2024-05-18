# nk3s-arm64-c

Rough documentation on my install process for NixOS on a Raspberry Pi 4B 8GB with the PoE Hat.

## Current Install

Using the nixos sd card images for the raspberry pi and otherwise following [Official Instructions](https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi). Did this to make supporting the PoE HAT easier.

## UEFI Attempt

### Preparation

This assumes (at time of writing) that you have the latest tow-boot shared image as your boot image on the SD card, then we re-build the SD card once booted into the live installer via USB.

```
git clone https://github.com/Tow-Boot/Tow-Boot.git
cd Tow-Boot
nix-build -A raspberryPi-aarch64
sudo dd if=result/shared.disk-image.img of=/dev/sdX bs=1M oflag=direct,sync status=progress
```

### Installation

Just a dump of all the commands I did to get it running with Tow-Boot and UEFI.

```
sudo su -
mkdir /FIRMWARE
cd /FIRMWARE
mkdir -p live
mkdir -p backup
mount /dev/mmcblk0p1 live
cp -R live/* backup/
umount /FIRMWARE/live
fdisk /dev/mmcblk0
> g
> n
> enter
> enter
> +32M
> t
> 11
> n
> enter
> enter
> +500M
> t
> 1
> n
> enter
> enter
> enter
> w
mkfs.fat -F 16 /dev/mmcblk0p1
mkfs.fat -F 32 /dev/mmcblk0p2
mkfs.ext4 -L nixos /dev/mmcblk0p3
gdisk /dev/mmcblk0
> r
> h
> 1
> n
> 0e
> n
> n
> w
mount /dev/mmcblk0p1 /FIRMWARE/live
cp -R /FIRMWARE/backup/* /FIRMWARE/live/
fatlabel /dev/mmcblk0p2 BOOTEFI
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOTEFI /mnt/boot
nixos-generate-config --root /mnt
cd /mnt
vim etc/nixos/configuration.nix
> canTouchEFIVars = false
> set hostName
> :wq
nixos-install
shutdown -r now
```

### First Run

This will be combined into the install step as soon as I have a stable/complete configuration. Login as root, then:

```
cd /etc/nixos
rm ./*
git clone https://github.com/wrmilling/nixos-configuration.git .
nixos-rebuild switch --flake .
passwd w4cbe
shutdown -r now
```