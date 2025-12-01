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
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use grub boot loader
  boot.loader.grub.enable = true;

  networking = {
    hostName = "linus"; # Define your hostname.
    domain = secrets.hosts.common.p_domain;
    nameservers = secrets.hosts.common.nameservers;
    interfaces.eth0 = {
      ipv4.addresses = [{
        address = secrets.hosts.linus.ipAddress;
        prefixLength = secrets.hosts.linus.prefixLength;
      }];
    };
    defaultGateway = {
      address = secrets.hosts.linus.gateway;
      interface = "eth0";
    };
  };

  services.openssh.banner = lib.mkForce secrets.sshd.p_banner;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "admin@${secrets.hosts.common.p_domain}";

  services = {
    headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8080;
      settings = {
        server_url = "https://h.${secrets.hosts.common.p_domain}";
        dns = {
          base_domain = "n.${secrets.hosts.common.p_domain}";
          nameservers.global = secrets.hosts.common.nameservers;
        };
      };
    };

    nginx.enable = true;
    nginx.virtualHosts."${secrets.hosts.common.p_domain}" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/${secrets.hosts.common.p_domain}";
    };

    nginx.virtualHosts."h.${secrets.hosts.common.p_domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
        proxyWebsockets = true;
      };
    };
  };

  environment.systemPackages = [ config.services.headscale.package ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home/server;
    };
  };

  system.stateVersion = "25.05";
}
