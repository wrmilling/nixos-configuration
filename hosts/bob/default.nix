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

      # "${secrets.hosts.common.b_domain}" = {
      #   forceSSL = true;
      #   enableACME = true;
      #   root = "/var/www/${secrets.hosts.common.b_domain}";
      # };

      "${secrets.hosts.common.m_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.m_domain}";
        locations = {
          "/" = {
            return = "302 https://${secrets.hosts.common.b_domain}$request_uri;";
          };
          "/.well-known/matrix/server" = {
            return = "200 '{\"m.server\": \"synapse.${secrets.hosts.common.domain}:443\"}'";
          };
          "/.well-known/matrix/client" = {
            return = "200 '{\"m.homeserver\": {\"base_url\": \"https://synapse.${secrets.hosts.common.domain}\"},\"org.matrix.msc2965.authentication\": {\"issuer\": \"https://synapse.${secrets.hosts.common.domain}/\",\"account\": \"https://mas.${secrets.hosts.common.domain}/account\"}}'";
            extraConfig = "add_header Content-Type application/json;\nadd_header \"Access-Control-Allow-Origin\" *;\n";
          };
          "/.well-known/webfinger" = {
            return = "301 https://mastodon.${secrets.hosts.common.domain}$request_uri";
          };
        };
      };

      # "${secrets.hosts.common.n_domain}" = {
      #   forceSSL = true;
      #   enableACME = true;
      #   root = "/var/www/${secrets.hosts.common.domain}";
      # };

      # "${secrets.hosts.common.y_domain}" = {
      #   forceSSL = true;
      #   enableACME = true;
      #   root = "/var/www/${secrets.hosts.common.domain}";
      # };

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
