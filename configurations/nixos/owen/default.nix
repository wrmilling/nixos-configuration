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

  sops.secrets."nixbuild/client-ssh-key" = {
    owner = "root";
    mode = "0400";
    sopsFile = ../../../secrets/nixbuild-arm.yaml;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  modules = {
    machineType.server.enable = true;
    nixos.sshd.banner = "${secrets.sshd.banner}";
    nixos.nixbuild-client = {
      enable = true;
      sshKeyPath = config.sops.secrets."nixbuild/client-ssh-key".path;
    };
  };

  # hardware.raspberry-pi."4".poe-hat.enable = true;

  # Artifact of the nixos user being created by default on the rpi images
  users.users.w4cbe.uid = lib.mkForce 1001;

  boot.kernelParams = [
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  networking = {
    hostName = "owen";
    domain = secrets.hosts.common-homelab.domain;
    useDHCP = lib.mkDefault true;
    interfaces = {
      end0.ipv4.addresses = [
        {
          address = secrets.hosts.owen.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.common-homelab.defaultGateway;
    nameservers = secrets.hosts.common-homelab.nameservers;
  };

  system.stateVersion = "25.05";
}
