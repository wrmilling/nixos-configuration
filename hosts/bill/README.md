# bill

This is a cheap 1 Core, 1GB ram KVM box from a random provider.

## Installation

```
$ ssh root@bill
$ sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get install -y vim curl
$ adduser w4cbe
$ usermod -a -G sudo w4cbe
$ logout
$ ssh w4cbe@bill
$ wget https://nixos.org/nix/install && sh install
$ . $HOME/.nix-profile/etc/profile.d/nix.sh
$ nix-channel --add https://nixos.org/channels/nixos-23.11 nixpkgs
$ nix-channel --update
$ nix-env -f '<nixpkgs>' -iA nixos-install-tools
$ sudo `which nixos-generate-config`
# Update /etc/nixos/configuration.nix and hardware-configuration.nix
# In this case, I specify a hefty swap partition to ensure things can build as well as my user account, sudo access, and a root password.
$ nix-env -p /nix/var/nix/profiles/system -f '<nixpkgs/nixos>' -I nixos-config=/etc/nixos/configuration.nix -iA system
$ sudo chown -R 0.0 /nix
$ sudo touch /etc/NIXOS /etc/NIXOS_LUSTRATE
$ echo etc/nixos | sudo tee -a /etc/NIXOS_LUSTRATE
$ sudo mv -v /boot /boot.bak
$ sudo mkdir /boot/
$ sudo NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
```