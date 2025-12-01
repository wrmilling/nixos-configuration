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
    appimage.enable = true;
    development.enable = true;
    dockerRootless.enable = true;
    gaming.enable = true;
    k8sUtils.enable = true;
    nvidia.enable = true;
    printing.enable = true;
    secureboot.enable = true;
    tailscale.enable = true;
    virtualization.enable = true;
    visualBoot.enable = true;
    vpn.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Since secureboot is enabled on this host and we have Windows on another drive, try to enable rebooting to windows:
  boot.lanzaboote.settings.reboot-for-bitlocker = true;

  # services.displayManager.sddm.wayland.enable = lib.mkForce false;

  services.onedrive.enable = true;

  networking = {
    hostName = "enterprise";
    domain = secrets.hosts.common.domain;
    # Though a desktop, has wifi for now, using networkmanager to manage.
    networkmanager.enable = true;
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
