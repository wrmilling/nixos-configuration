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
    ../common/optional/k3s-agent-arm.nix
    ../common/optional/reboot-required.nix
  ];

  hardware.raspberry-pi."4".poe-hat.enable = true;

  boot.kernelParams = [
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  networking = {
    hostName = "nk3s-arm64-b";
    domain = secrets.hosts.common-k3s.domain;
    useDHCP = lib.mkDefault true;
    interfaces = {
      end0.ipv4.addresses = [
        {
          address = secrets.hosts.nk3s-arm64-b.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.common-k3s.defaultGateway;
    nameservers = secrets.hosts.common-k3s.nameservers;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "24.11";
}
