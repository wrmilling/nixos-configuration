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
    nixos.sshd.banner = "${secrets.sshd.c_banner}";
    nixos.webhost.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "khan"; # Define your hostname.
    domain = secrets.hosts.common.c_domain;
    nameservers = secrets.hosts.common.nameservers;
    dhcpcd.extraConfig = "nohook resolv.conf";
  };

  services.nginx = {
    virtualHosts = {
      "${secrets.hosts.common.c_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.c_domain}";
      };
      "irc.${secrets.hosts.common.c_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.c_domain}";
      };
    };
  };

  security.acme.certs."irc.${secrets.hosts.common.c_domain}".postRun = "cat /var/lib/acme/irc.${secrets.hosts.common.c_domain}/{privkey,fullchain}.pem > /var/lib/znc/znc.pem && chown znc:znc /var/lib/znc/znc.pem";

  networking.firewall.allowedTCPPorts = [
    secrets.hosts.khan.zncPort
  ];

  services.znc = {
    enable = true;
    mutable = true;
    useLegacyConfig = false;
  };

  system.stateVersion = "25.05";
}
