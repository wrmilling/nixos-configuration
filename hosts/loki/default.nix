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
    ../common/desktop.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enabled lanzaboote through secureboot.nix optional import.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "loki";
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
