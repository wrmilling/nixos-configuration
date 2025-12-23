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
    inputs.hardware.nixosModules.lenovo-legion-y530-15ich
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.laptop.enable = true;
    nixos.appimage.enable = true;
    nixos.development.enable = true;
    nixos.dockerRootless.enable = true;
    nixos.flipper.enable = true;
    nixos.gaming.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.printing.enable = true;
    nixos.tailscale.enable = true;
    nixos.virtualization.enable = true;
    nixos.visualBoot.enable = true;
    nixos.vpn.enable = true;
    nixos.wireshark.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "donnager";
    domain = secrets.hosts.common.domain;
  };

  system.stateVersion = "24.11";
}
