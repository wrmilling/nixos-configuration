{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
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
  # boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  networking = {
    hostName = "donnager";
    domain = secrets.machines.donnager.domain;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/donnager;
    };
  };
  
  system.stateVersion = "23.05"; # Did you read the comment?
}

