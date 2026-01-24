# icarus

Icarus is an HP EliteBook 845 G8 with the Ryzen 5 PRO 5650U, these are the steps that I initially took to install NixOS, though once the config is setup it can just be re-used for future re-installs if needed. This assumes you have booted into a NixOS install image from a USB stick, that we are installing with Full Disk Encryption, and that we will be using systemd-boot.

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
$ sudo fatlabel /dev/nvm0n1p1 BOOTEFI
$ sudo cryptsetup luksFormat /dev/nvm0n1p2
> YES
> <password>
> <password>
$ sudo cryptsetup luksOpen /dev/nvm0n1p2 cryptroot
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

Next I will normally open the hardware and configuration nix files to clean out comments and set basic information like hostname. Most of my other items are set by my profiles or modules so I will take care of those later.

Now, lets install:

```
$ cd /mnt
$ sudo nixos-install
> <root password when prompted>
$ sudo reboot
```

### First Run

Here is where I will normally try and setup all the hardware and import the profiles/modules I want from this repo. Since I use the minimal install, I will kick things off like so:

```
$ nix-shell -p git vim
$ cd /etc/nixos
$ git clone https://github.com/wrmilling/nixos-configuration.git .
```

I will then copy in the new machine basic config into a new machine folder and setup the configuration.nix in root. I will then replace the generated config with the new setup.

```
$ mkdir -p hosts/icarus
$ mv ../configuration.nix hosts/icarus/default.nix
$ mv ../hardware-configuration.nix hosts/icarus/hardware.nix
$ vim hosts/icarus/default.nix
# Update the link to hardware.nix and add all modules/profiles as required.
```

I will then be able to update the nixos-configuration repo in github and just pull/rebuild as needed on the machine. You will need to comment out lanzaboote module in the flake definition for this machine and comment out the secure boot optional import in the hosts/<machine>/default.nix to hve this run successfully prior to onboarding Secure Boot and TPM2 for LUKS.

```
$ sudo sh -c "cd /etc/nixos && git pull && nixos-rebuild switch --flake ."
```

The above is aliased to `nrs` on my machines.

### Secure Boot

I also enabled secure boot on this machine using [lanzaboote](https://github.com/nix-community/lanzaboote) which followed their [guide](https://github.com/nix-community/lanzaboote/blob/d32b80889700ec1479d19d08ebfdb9880a4e76d7/docs/QUICK_START.md) for setup. For the ELitebook, disabling Secure Boot in bios will put it into setup mode and by inporting your keys it will enable Secure Boot. The shortlist of commands are below, but read the guide for the latest:

```
# Disable Secure Boot in BIOS, F10 at startup to get into BIOS
# Ensure you see disabled in NixOS, e.g. "Secure Boot: disabled (disabled)"
$ bootctl status

# Create Keys for Secure Boot
$ sudo sbctl create-keys

# Import Lanzaboote and generate new signed EFI blobs, already done for Icarus
$ sudo sh -c "cd /etc/nixos && git pull && nixos-rebuild switch --flake ."

# Verify generations and BOOTX64.EFI and systemd-bootx84.efi are signed.
$ sudo sbctl verify

# Encroll keys onto machine for Secure Boot
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