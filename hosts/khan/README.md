# khan

This is a Oracle Free Tier VM.Standard.E2.1.Micro system.

## Installation

### Create Your Machine

Register for Oracle Free tier and create an instance in your desired size running the latest LTS of Ubuntu available as a free-tier image. This may also require setting up an Oracle [VCN](https://www.oracle.com/cloud/networking/virtual-cloud-network/) (its been a minute since I did initial setup) with your desired ports open for the instance, google is a friend here.

For my instance, I built the VVM.Standard.E2.1.Micro with 1 OCPU and 1GB of memory. For my block storage, I chose 50GB to be allocated to this instance, the other 150GB in the free tier being allocated to the also-free ARM64 instance available at Oracle.

Once your machine is created, its time to...

### Install Nix

```
$ sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
$ . $HOME/.nix-profile/etc/profile.d/nix.sh
$ nix-channel --add https://nixos.org/channels/nixos-25.05 nixpkgs
$ nix-channel --update
$ nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter ]"
$ sudo `which nixos-generate-config` --root /
# Update /etc/nixos/configuration.nix and hardware-configuration.nix
# Be sure to specify mount efi partition to /boot directly rather than /boot/efi
# In this case, I specify a hefty swap partition to ensure things can build
$ nix-env -p /nix/var/nix/profiles/system -f '<nixpkgs/nixos>' -I nixos-config=/etc/nixos/configuration.nix -iA system
$ sudo chown -R 0:0 /nix
$ sudo touch /etc/NIXOS /etc/NIXOS_LUSTRATE
$ echo etc/nixos | sudo tee -a /etc/NIXOS_LUSTRATE
$ sudo umount /boot/EFI && sudo umount /boot
$ sudo mkdir -p /boot
$ sudo mount /dev/sda15 /boot
$ sudo rm -rf /boot/EFI
$ sudo NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
$ sudo shutdown -r now
```

# Config example

Config additions which I may need for rebuilds in the future:

```
  time.timeZone = "Europe/Chicago";
  services.openssh.enable = true;
  users.users.w4cbe = {
    uid = 1000;
    isNormalUser = true;
    home = "/home/w4cbe";
    description = "Winston R. Milling";
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7AItff1gZXXS0qVsAIy8qBz4e/1etAArnj+qccuUVwf8ybAYQwD4910h1D4rFBSjf9KmMdY1nesprNKM8ICeA5jSH7kblkRYOB3nUjg5B/GqWDgtjU4ooJBBP7ibuqZfbwDzTPH1Cuodc4CBPdy/yulCHpAZRU7YauXxXvQOckbd8uHoPC5wggQSjVszsyfaQGTx0N0hMv1aHBPstp9It9JiHuxtwSvyctRiXFdWdmsBbTla086Nuc8uFoaKWiuxIRyplW0qSswIbrBdVUY7q+ss38pjcDhHSag3tItEU9FRBfYkcT3PxsmHFYTgjX4bNl2Y1VcxQ0n3Fs5yZYWZcbDtooPrHSyMwaoqm+QECIu6nKSVsa/Iq0d/3JaA8MJZ/zV1JlydSMcfi2XcXYvJauyuQgwOVIyXhb6N/zTs4pgwlVMkxtUCatPe2zWHvfRBOtfNbw1zDW/pzh/lJcIPuWmESv/zPcsJC4r+cD0lASi+UjZyIeVOaKuhznO7kRPfRO4H8BwW4T2qSo5xDrjR7gR820TyJWEUZbMdMByrgZvWyJEoxPfrAhMQdtnbaX0nRvdYcori/cL1b8QxUZTLdZgwVaxeyh0/P5fOK01OO9MH7O19ZtkkAx9dswk1Y5rQWzmQp6Ab+pAizPNZBwNDxdQaoB48ZAX/KDG3jmSdZgw=="
    ];
  };
  users.users.root.password = "firstbootpassword";
```