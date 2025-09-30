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
    ../common/laptop.nix
    ../common/optional/3d-printing.nix
    ../common/optional/amateur-radio.nix
    ../common/optional/appimage.nix
    ../common/optional/development.nix
    ../common/optional/flipper.nix
    ../common/optional/gaming.nix
    ../common/optional/k8s-utils.nix
    ../common/optional/printing.nix
    ../common/optional/secureboot.nix
    ../common/optional/smartcard.nix
    ../common/optional/tailscale.nix
    ../common/optional/virtualization.nix
    ../common/optional/visual-boot.nix
    ../common/optional/wireshark.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enabled lanzaboote through secureboot.nix optional import.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "icarus";
    domain = secrets.hosts.common.domain;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home-manager/w4cbe;
    };
  };

  system.stateVersion = "25.05";
}
