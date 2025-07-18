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
    ../common/optional/nixbuild-host.nix
    ../common/optional/webhost.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "bob"; # Define your hostname.
    domain = secrets.hosts.common.domain;
    nameservers = secrets.hosts.common.nameservers;
  };

  services.uptime-kuma = {
    enable = true;
    package = pkgs.uptime-kuma;
  };

  services.nginx = {
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "${secrets.hosts.common.domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.domain}";
      };

      # "${secrets.hosts.bob.alt1Domain}" = {
      #   forceSSL = true;
      #   enableACME = true;
      #   root = "/var/www/${secrets.hosts.common.domain}";
      # };

      "${secrets.hosts.bob.alt2Domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.domain}";
      };

      "status.${secrets.hosts.common.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:3001/";
          proxyWebsockets = true;
        };
      };
    };
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
