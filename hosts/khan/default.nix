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
    ../common/server.nix
    ../common/optional/webhost.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh.banner = lib.mkForce secrets.sshd.alt_banner;

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
    };
  };

  services.znc = {
    enable = true;
    mutable = true;
    useLegacyConfig = true;
    confOptions.port = ${secrets.hosts.khan.zncPort};
    openFirewall = true;
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
