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
    ../common/server.nix
    # ../common/optional/pihole.nix
  ];

  hardware.raspberry-pi."4".poe-hat.enable = true;

  # Artifact of the nixos user being created by default on the rpi images
  users.users.w4cbe.uid = 1001;

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
