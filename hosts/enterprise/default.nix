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
    ../common/optional/plasma6.nix
    ../common/optional/printing.nix
    ../common/optional/tailscale.nix
    ../common/optional/virtualization.nix
    ../common/optional/visual-boot.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # services.displayManager.sddm.wayland.enable = lib.mkForce false;

  networking = {
    hostName = "enterprise";
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
