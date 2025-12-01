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
    threeDPrinting.enable = true;
    amateurRadio.enable = true;
    appimage.enable = true;
    development.enable = true;
    dockerRootless.enable = true;
    flipper.enable = true;
    gaming.enable = true;
    k8sUtils.enable = true;
    printing.enable = true;
    secureboot.enable = true;
    smartcard.enable = true;
    tailscale.enable = true;
    virtualization.enable = true;
    visualBoot.enable = true;
    vpn.enable = true;
    wireshark.enable = true;
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

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home/w4cbe;
    };
  };

  system.stateVersion = "25.05";
}
