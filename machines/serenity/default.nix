{ config, inputs, lib, pkgs, ... }:

let secrets = import ../../secrets.nix; in 

{  
  imports =
    [ 
      inputs.hardware.nixosModules.git pine64-pinebook-pro
      ./hardware.nix
      ../common/laptop.nix
      ../common/addons/development.nix
      ../common/addons/k8s-utils.nix
      ../common/addons/nixbuild-client.nix
      ../common/addons/tailscale.nix
      ../common/addons/virtualization.nix
      ../common/addons/zram.nix
    ];
  
  networking = {
    hostName = "serenity";
    # domain = secrets.DOMAIN;
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
	
	home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/serenity;
    };
  };

  system.stateVersion = "23.05"; 
}
