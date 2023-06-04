{ config, lib, pkgs, ... }:

let secrets = import ../../secrets.nix; in 

{  
  imports =
    [ 
      <nixos-hardware/pine64/pinebook-pro>
      ./hardware.nix
      ../../profiles/laptop.nix
      ../../addons/development.nix
      ../../addons/k8s-utils.nix
      ../../addons/nixbuild-client.nix
      ../../addons/tailscale.nix
      ../../addons/virtualization.nix
      ../../addons/zram.nix
    ];
  
  networking = {
    hostName = "serenity";
    domain = secrets.DOMAIN;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelParams = lib.mkAfter [ "console=tty0" ];

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-uuid/f9618ef7-0e79-4181-8a05-d95c300bb10f";
      allowDiscards = true;
      preLVM = true;
    };
  };

  environment.etc = {
    crypttab = {
      text = ''
        nvmecrypt /dev/disk/by-uuid/92cf1e12-72a6-48fd-911f-5249183e5c64 /home/luks/nvme.key luks
      '';
      mode = "0440";
    };
  };
  
  system.stateVersion = "22.11"; 
}
