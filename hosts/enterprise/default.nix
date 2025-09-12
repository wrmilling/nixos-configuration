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
    ../common/optional/appimage.nix
    ../common/optional/development.nix
    ../common/optional/gaming.nix
    ../common/optional/k8s-utils.nix
    ../common/optional/nvidia.nix
    ../common/optional/printing.nix
    ../common/optional/secureboot.nix
    ../common/optional/tailscale.nix
    ../common/optional/virtualization.nix
    ../common/optional/visual-boot.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Since secureboot is enabled on this host and we have Windows on another drive, try to enable rebooting to windows:
  boot.lanzaboote.settings.reboot-for-bitlocker = true;

  # services.displayManager.sddm.wayland.enable = lib.mkForce false;

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
      w4cbe = import ../../home-manager/w4cbe;
    };
  };

  system.stateVersion = "24.11";
}
