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
    ../common/optional/amateur-radio.nix
    ../common/optional/development.nix
    ../common/optional/docker-rootless.nix
    ../common/optional/flipper.nix
    ../common/optional/k8s-utils.nix
    ../common/optional/printing.nix
    ../common/optional/secureboot.nix
    ../common/optional/wireshark.nix
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
