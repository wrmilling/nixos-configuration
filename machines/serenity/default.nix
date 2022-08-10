{ config, lib, pkgs, ... }:

let private = import ./private.nix; in 

{  
  imports =
    [ 
      ../../hardware/pine64/pinebook-pro
      ../../hardware/profiles/laptop.nix
      ./hardware.nix
      ../../modules/zram.nix
      ../../profiles/desktop.nix
      ../../profiles/i3wm.nix
      ../../modules/audio.nix
      ../../modules/k8s.nix
    ];
  
  networking = {
    hostName = "serenity";
    domain = private.DOMAIN;
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
