{
  config,
  inputs,
  outputs,
  pkgs,
  lib,
  secrets,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.apple-macbook-pro-11-1
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.laptop.enable = true;
    nixos.appimage.enable = true;
    nixos.development.enable = true;
    nixos.gaming.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.printing.enable = true;
    nixos.tailscale.enable = true;
    nixos.visualBoot.enable = true;
    nixos.zram.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "bender";
    domain = secrets.hosts.common.domain;
  };

  system.stateVersion = "24.11";
}
