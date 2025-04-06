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
    ../common/laptop.nix
    ../common/users/haley.nix
    ../common/optional/appimage.nix
    ../common/optional/development.nix
    ../common/optional/gaming.nix
    ../common/optional/k8s-utils.nix
    ../common/optional/plasma6.nix
    ../common/optional/printing.nix
    ../common/optional/tailscale.nix
    ../common/optional/visual-boot.nix
    ../common/optional/zram.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "bender";
    domain = secrets.hosts.common.domain;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home-manager/w4cbe;
      haley = import ../../home-manager/haley;
    };
  };

  system.stateVersion = "24.11";
}
