{ config, inputs, outputs, secrets, lib, pkgs, ... }:

{  
  imports =
    [ 
      inputs.hardware.nixosModules.pine64-pinebook-pro
      inputs.home-manager.nixosModules.home-manager
      ./hardware.nix
      ../common/laptop.nix
      ../common/modules/i3wm.nix
      ../common/addons/development.nix
      ../common/addons/k8s-utils.nix
      ../common/addons/tailscale.nix
      ../common/addons/virtualization.nix
      ../common/addons/zram.nix
    ];
  
  networking = {
    hostName = "serenity";
    domain = secrets.hosts.serenity.domain;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelParams = lib.mkAfter [ "console=tty0" ];

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-uuid/54c4fcbf-feb8-4029-958f-0cb12b8e2e59";
      allowDiscards = true;
      preLVM = true;
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
