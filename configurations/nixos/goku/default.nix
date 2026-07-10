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
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.server.enable = true;
    nixos.sshd.banner = "${secrets.sshd.banner}";
    nixos.forgejoRunner = {
      enable = true;
      domain = secrets.forgejo.domain;
      runnerTokenFile = config.sops.secrets."forgejo/runnerToken".path;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Use grub boot loader
  boot.loader.grub.enable = true;
  services.qemuGuest.enable = true;

  networking = {
    hostName = "goku"; # Define your hostname.
    domain = secrets.hosts.common.domain;
    nameservers = secrets.hosts.common.nameservers;
  };

  sops.secrets."forgejo/runnerToken" = {
    sopsFile = ../../../secrets/forgejo.yaml;
  };

  system.stateVersion = "25.05";
}
