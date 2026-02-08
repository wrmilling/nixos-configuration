{
  config,
  inputs,
  outputs,
  secrets,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.pine64-pinebook-pro
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.laptop.enable = true;
    nixos.amateurRadio.enable = true;
    nixos.development.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.tailscale.enable = true;
    nixos.virtualization.enable = true;
    nixos.visualBoot.enable = true;
    nixos.zram.enable = true;
  };

  networking = {
    hostName = "riker";
    domain = secrets.hosts.common.domain;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelParams = lib.mkAfter [ "console=tty0" ];

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-uuid/ddce2ffe-beb7-4e54-a2ff-f0759d15d55d";
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

  system.stateVersion = "24.11";
}
