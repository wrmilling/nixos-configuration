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
    nixos.development.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.tailscale.enable = true;
    nixos.virtualization.enable = true;
    nixos.zram.enable = true;
  };

  networking = {
    hostName = "serenity";
    domain = secrets.hosts.common.domain;
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

  system.stateVersion = "24.11";
}
