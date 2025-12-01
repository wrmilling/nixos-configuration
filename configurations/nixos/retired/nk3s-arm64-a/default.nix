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

  sops.secrets."k3s/agent/nodeTokenFull" = {
    sopsFile = ../../../secrets/k3s.yaml;
  };

  modules = {
    machineType.server.enable = true;
    rebootRequired.enable = true;
    k3sAgentArm = {
      enable = true;
      tokenFile = config.sops.secrets."k3s/agent/nodeTokenFull".path;
    };
  };

  hardware.raspberry-pi."4".poe-hat.enable = true;

  boot.kernelParams = [
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  networking = {
    hostName = "nk3s-arm64-a";
    domain = secrets.hosts.common-homelab.domain;
    useDHCP = lib.mkDefault true;
    interfaces = {
      end0.ipv4.addresses = [
        {
          address = secrets.hosts.nk3s-arm64-a.address;
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
      w4cbe = import ../../home/server;
    };
  };

  system.stateVersion = "24.11";
}
