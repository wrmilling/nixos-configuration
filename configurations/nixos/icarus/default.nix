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
    inputs.hardware.nixosModules.hp-elitebook-845g8
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.laptop.enable = true;
    nixos.threeDPrinting.enable = true;
    nixos.amateurRadio.enable = true;
    nixos.appimage.enable = true;
    nixos.development.enable = true;
    nixos.dockerRootless.enable = true;
    nixos.flipper.enable = true;
    nixos.gaming.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.printing.enable = true;
    nixos.secureboot.enable = true;
    nixos.smartcard.enable = true;
    nixos.tailscale.enable = true;
    nixos.virtualization.enable = true;
    nixos.visualBoot.enable = true;
    nixos.vpn.enable = true;
    nixos.wireshark.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enabled lanzaboote through secureboot.nix optional import.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.onedrive.enable = true;

  networking = {
    hostName = "icarus";
    domain = secrets.hosts.common.domain;
  };

  system.stateVersion = "25.05";
}
