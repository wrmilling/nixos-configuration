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
    ../common/laptop.nix
    ../common/optional/appimage.nix
    ../common/optional/development.nix
    ../common/optional/docker.nix
    ../common/optional/flipper.nix
    ../common/optional/gaming.nix
    ../common/optional/k8s-utils.nix
    ../common/optional/printing.nix
    ../common/optional/tailscale.nix
    ../common/optional/virtualization.nix
    ../common/optional/visual-boot.nix
    ../common/optional/wireshark.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "donnager";
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

  system.stateVersion = "24.11";
}
