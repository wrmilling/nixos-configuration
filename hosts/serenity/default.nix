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
    development.enable = true;
    k8sUtils.enable = true;
    tailscale.enable = true;
    virtualization.enable = true;
    zram.enable = true;
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

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home-manager/serenity;
    };
  };

  system.stateVersion = "24.11";
}
