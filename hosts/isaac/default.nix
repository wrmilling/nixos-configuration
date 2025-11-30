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
    inputs.hardware.nixosModules.raspberry-pi-4
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  sops.secrets."pihole/additionalHosts" = {
    owner = "pihole";
    sopsFile = ../../../secrets/pihole.yaml;
  };

  sops.secrets."pihole/customAddresses" = {
    owner = "pihole";
    sopsFile = ../../../secrets/pihole.yaml;
  };

  sops.secrets."pihole/customCnames" = {
    owner = "pihole";
    sopsFile = ../../../secrets/pihole.yaml;
  };

  modules = {
    machineType.server.enable = true;
    pihole = {
      enable = true;
      additionalHosts = config.sops.secrets."pihole/additionalHosts".path;
      customAddresses = config.sops.secrets."pihole/customAddresses".path;
      customCnames = config.sops.secrets."pihole/customCnames".path;
    };
  };

  hardware.raspberry-pi."4".poe-hat.enable = true;

  # Artifact of the nixos user being created by default on the rpi images
  users.users.w4cbe.uid = lib.mkForce 1001;

  boot.kernelParams = [
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  networking = {
    hostName = "isaac";
    domain = secrets.hosts.common-homelab.domain;
    useDHCP = lib.mkDefault true;
    interfaces = {
      end0.ipv4.addresses = [
        {
          address = secrets.hosts.isaac.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.common-homelab.defaultGateway;
    nameservers = secrets.hosts.common-homelab.nameservers;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "25.05";
}
