{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [
      inputs.hardware.nixosModules.lenovo-legion-y530-15ich
      inputs.home-manager.nixosModules.home-manager    
      ./hardware.nix
      ../common/laptop.nix
      ../common/addons/development.nix
      ../common/addons/gaming.nix
      ../common/addons/k8s-utils.nix
      ../common/addons/tailscale.nix
      ../common/addons/virtualization.nix
      ../common/addons/zram.nix
    ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Visual boot
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" ];

  networking = {
    hostName = "donnager";
    domain = secrets.hosts.donnager.domain;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/donnager;
    };
  };
  
  system.stateVersion = "23.05";
}

