# bart

This is a cheap 1 Core, 2GB ram KVM box from a random provider. I used Ubuntu 20.04 as the base image to modify into NixOS.

## Installation

```
$ ssh root@bart
$ sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get install -y vim curl
$ adduser w4cbe
$ usermod -a -G sudo w4cbe
$ logout
$ ssh w4cbe@bart
$ wget https://nixos.org/nix/install && sh install
$ . $HOME/.nix-profile/etc/profile.d/nix.sh
$ nix-channel --add https://nixos.org/channels/nixos-23.11 nixpkgs && nix-channel --update
$ nix-env -f '<nixpkgs>' -iA nixos-install-tools
$ sudo `which nixos-generate-config`
# Update /etc/nixos/configuration.nix and hardware-configuration.nix
# In this case, I specify a hefty swap partition to ensure things can build as well as my user account, sudo access, a root password, and an active ssh server.
$ nix-env -p /nix/var/nix/profiles/system -f '<nixpkgs/nixos>' -I nixos-config=/etc/nixos/configuration.nix -iA system
$ sudo chown -R 0:0 /nix
$ sudo touch /etc/NIXOS /etc/NIXOS_LUSTRATE
$ echo etc/nixos | sudo tee -a /etc/NIXOS_LUSTRATE
$ sudo mv -v /boot /boot.bak
$ sudo mkdir /boot/
$ sudo NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
$ sudo shutdown -r now
```

## Example Configuration Additions

### configuration.nix

```
  boot.loader.grub.device = "/dev/vda";
  networking.hostName = "bart";
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