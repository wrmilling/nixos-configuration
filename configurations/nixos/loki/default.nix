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
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.desktop.enable = true;
    nixos.amateruRadio.enable = true;
    nixos.development.enable = true;
    nixos.dockerRootless.enable = true; 
    nixos.flipper.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.printing.enable = true;
    nixos.secureboot.enable = true;
    nixos.wireshark.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enabled lanzaboote through secureboot.nix optional import.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "loki";
    domain = secrets.hosts.common.domain;
  };

  system.stateVersion = "25.05";
}
