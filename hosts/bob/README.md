# bob

![neofetch screenshot](https://i.imgur.com/9aienJ6.png)

`bob` is part of a new series of machine names, reserved for servers and based on the [Bobiverse](https://bobiverse.fandom.com/wiki/We_Are_Legion_\(We_Are_Bob\)_Wiki) series of characters, because I am bad at naming.

First iteration is based on an OpenVZ server because I have it laying around, `bob` as a name will probably be re-used for other servers in the future.

`bob` is currently not 100% happy due to a systemd bug impacting resolved.

## Installation

Utilizing [this project](https://github.com/zhaofengli/nixos-openvz/) to get NixOS on an OpenVZ VPS. I am starting with a Debian 10 OpenVZ instance, not sure if it is OpenVZ 7 or 8, but we are trying. Commands in order on your local machine:


```
$ git clone https://github.com/zhaofengli/nixos-openvz.git
$ cd nixos-openvz.git
$ vim configuration.nix
```

Contents of said file:

```
{
  networking.useNetworkd = true;

  systemd.network.networks.venet0 = {
    name = "venet0";
    # Change to your assigned IP
    address = [ "10.10.10.123/32" ];
    networkConfig = {
      DHCP = "no";
      DefaultRouteOnDevice = "yes";
      ConfigureWithoutCarrier = "yes";
    };
  };

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa ...."
  ];
}
```

Now execute the build, upload the tarball, and use it.

```
$ nix-build generate-openvz-tarball.nix --arg configuration ./configuration.nix
$ scp result/tarball/nixos-system-x86_64-linux.tar.xz root@<REMOTE>:/root/nixos-system-x86_64-linux.tar.xz
$ ssh root@<REMOTE>
$ tar xpf nixos-system-x86_64-linux.tar.xz -C /
$ reboot -f
```

Once it reboots you should be in a nixos install.

## Updating

The OpenVZ instance does not have enough memory to do a nixos-rebuild switch locally, so I am currently using donnager as my build machine and pushing the changes to the server via:

```
nixos-rebuild switch --target-host root@bob --flake .#bob
```
