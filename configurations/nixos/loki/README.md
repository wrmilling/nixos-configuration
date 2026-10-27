# loki

loki is an Lenovo ThinkCentre M715q with 16GB ram and a 250GB drive. 

## Installation

### Disk Setup

Creates 2 partitions on the drive, one for EFI Boot and one for the luks encrypted root.

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

I will then move the generated config into a new host folder under `configurations/nixos/`, where the flake picks it up automatically as `nixosConfigurations.loki`.

```
$ mkdir -p configurations/nixos/loki
$ mv ../configuration.nix configurations/nixos/loki/default.nix
$ mv ../hardware-configuration.nix configurations/nixos/loki/hardware.nix
$ vim configurations/nixos/loki/default.nix
# Import ./hardware.nix and enable the machineType/component modules as required.
```

I will then be able to update the nixos-configuration repo in github and just pull/rebuild as needed on the machine. Until Secure Boot and TPM2 for LUKS are onboarded, set `modules.nixos.secureboot.enable = false;` in `configurations/nixos/loki/default.nix` so this first rebuild uses plain systemd-boot.

```
$ sudo nixos-rebuild switch --flake .#loki
```

After the first switch, I keep the repo at `~/.nixos-configuration` and rebuild with [nh](https://github.com/nix-community/nh):

```
$ cd ~/.nixos-configuration
$ git pull
$ nh os switch .
$ nh home switch .
```

The above is aliased to `nhs` on my machines.

### Secure Boot

I also enabled secure boot on this machine using [lanzaboote](https://github.com/nix-community/lanzaboote) which followed their [guide](https://github.com/nix-community/lanzaboote/blob/d32b80889700ec1479d19d08ebfdb9880a4e76d7/docs/QUICK_START.md) for setup. Disabling Secure Boot in the firmware setup puts it into setup mode, and enrolling your keys turns Secure Boot back on. The shortlist of commands is below, but read the guide for the latest:

```
# Disable Secure Boot in the firmware setup
# Ensure you see disabled in NixOS, e.g. "Secure Boot: disabled (disabled)"
$ bootctl status

# Create Keys for Secure Boot
$ sudo sbctl create-keys

# Set modules.nixos.secureboot.enable = true again and rebuild to generate signed EFI blobs
$ nh os switch .

# Verify generations and BOOTX64.EFI and systemd-bootx64.efi are signed.
$ sudo sbctl verify

# Enroll keys onto machine for Secure Boot
$ sudo sbctl enroll-keys --microsoft

# Reboot the machine
$ sudo shutdown -r now

# Verify Secure Boot is enabled, expected "Secure Boot: enabled (user)"
$ bootctl status

```

### TPM2 LUKS Unlock

I also followed [this guide](https://discourse.nixos.org/t/a-modern-and-secure-desktop-setup/41154) for enabling LUKS unlock using TPM2, which also references the Secure Boot instructions mentioned above. Essentially, it boils down to the following command:

```
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs="0+2+3+5+7+8+12+13+14+15:sha256=0000000000000000000000000000000000000000000000000000000000000000" /dev/<root-partition>
```

As well as updating `hardware.nix` to include a few extra crypttab options:

```
# Modify HW config
boot.initrd.luks.devices."cryptroot" = {
  device = "/dev/disk/by-uuid/<...>";
  crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-measure-pcr=yes" ];
};
```

## Outro

Good luck!