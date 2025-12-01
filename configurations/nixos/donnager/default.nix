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
    appimage.enable = true;
    development.enable = true;
    dockerRootless.enable = true;
    flipper.enable = true;
    gaming.enable = true;
    k8sUtils.enable = true;
    printing.enable = true;
    tailscale.enable = true;
    virtualization.enable = true;
    visualBoot.enable = true;
    vpn.enable = true;
    wireshark.enable = true;
  };

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
      w4cbe = import ../../home/w4cbe;
    };
  };

  system.stateVersion = "24.11";
}
