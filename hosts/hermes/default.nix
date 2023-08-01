{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      ./hardware.nix
      ../common/server.nix
      ../common/addons/webhost.nix
    ];

  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages
    ];
  };

  # https://github.com/NixOS/nixpkgs/issues/229450
  environment.systemPackages = with pkgs; [
    unstable.e2fsprogs
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "hermes"; # Define your hostname.
    domain = secrets.hosts.hermes.domain;
  };

  services.nginx.virtualHosts."${secrets.hosts.hermes.domain}" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/${secrets.hosts.hermes.domain}";
  };

  sops.defaultSopsFile = ../../secrets/hermes.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.05";
}

