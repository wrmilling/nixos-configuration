{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [
      inputs.hardware.nixosModules.raspberry-pi-4
      inputs.home-manager.nixosModules.home-manager
      ./hardware.nix
      ../common/server.nix
      # ../common/optional/k3s-agent.nix
    ];

  hardware.raspberry-pi."4".poe-hat.enable = true;

  boot.kernelParams = [
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  networking = {
    hostName = "nk3s-arm64-c";
    domain = secrets.hosts.nk3s-arm64-c.domain;
    useDHCP = lib.mkDefault true;
    interfaces = {
      end0.ipv4.addresses = [
        {
          address = secrets.hosts.nk3s-arm64-c.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.nk3s-arm64-c.defaultGateway;
    nameservers = secrets.hosts.nk3s-arm64-c.nameservers;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.05";
}
