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
    # users.haley.enable = true;
    appimage.enable = true;
    development.enable = true;
    gaming.enable = true;
    k8sUtils.enable = true;
    printing.enable = true;
    tailscale.enable = true;
    visualBoot.enable = true;
    zram.enable = true;
  };

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
      w4cbe = import ../../home/w4cbe;
      haley = import ../../home/haley;
    };
  };

  system.stateVersion = "24.11";
}
