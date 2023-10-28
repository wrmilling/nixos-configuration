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

  networking = {
    hostName = "nk3s-arm64-b";
    domain = secrets.hosts.nk3s-arm64-b.domain;
    useDHCP = lib.mkDefault true;
    interfaces = {
      end0.ipv4.addresses = [
        {
          address = secrets.hosts.nk3s-arm64-b.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.nk3s-arm64-b.defaultGateway;
    nameservers = secrets.hosts.nk3s-arm64-b.nameservers;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.05";
}
