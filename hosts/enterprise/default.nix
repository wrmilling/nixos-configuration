{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./hardware.nix
      ../common/desktop.nix
      ../common/optional/appimage.nix
      ../common/optional/development.nix
      ../common/optional/gaming.nix
      ../common/optional/k8s-utils.nix
      ../common/optional/nvidia.nix
      ../common/optional/printing.nix
      ../common/optional/tailscale.nix
      ../common/optional/virtualization.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Visual boot
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" ];

  networking = {
    hostName = "enterprise";
    domain = secrets.hosts.enterprise.domain;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/enterprise;
    };
  };

  system.stateVersion = "23.11";
}

