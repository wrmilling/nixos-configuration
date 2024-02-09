# goku

This is a Oracle Free Tier VM.Standard.E2.1.Micro system.

## Installation

### Create Your Machine

Register for Oracle Free tier and create an instance in your desired size running the latest LTS of Ubuntu available as a free-tier image. This may also require setting up an Oracle [VCN](https://www.oracle.com/cloud/networking/virtual-cloud-network/) (its been a minute since I did initial setup) with your desired ports open for the instance, google is a friend here.

For my instance, I built the VVM.Standard.E2.1.Micro with 1 OCPU and 1GB of memory. For my block storage, I chose 50GB to be allocated to this instance, the other 150GB in the free tier being allocated to the also-free ARM64 instance available at Oracle.

Once your machine is created, its time to...

### Install Nix

```
$ curl https://nixos.org/nix/install | sh
$ . $HOME/.nix-profile/etc/profile.d/nix.sh
$ nix-channel --add https://nixos.org/channels/nixos-23.11 nixpkgs
$ nix-channel --update
$ nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"
$ sudo `which nixos-generate-config` --root /
# Update /etc/nixos/configuration.nix and hardware-configuration.nix
# Be sure to specify mount efi partition to /boot directly rather than /boot/efi
# In this case, I specify a hefty swap partition to ensure things can build
$ nix-env -p /nix/var/nix/profiles/system -f '<nixpkgs/nixos>' -I nixos-config=/etc/nixos/configuration.nix -iA system
$ sudo chown -R 0.0 /nix
$ sudo touch /etc/NIXOS /etc/NIXOS_LUSTRATE
$ echo etc/nixos | sudo tee -a /etc/NIXOS_LUSTRATE
$ sudo mv -v /boot /boot.bak
$ sudo mkdir /boot/
$ sudo umount /boot.bak/efi
$ sudo mount /dev/nvme0n1p1 /boot
$ sudo mv /boot/EFI /boot.bak/efi/
$ sudo NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
```