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

  users.users.deploy = {
    uid = 1050;
    shell = pkgs.bash;
    isNormalUser = true;
    home = "/home/deploy";
    description = "Site Deployment User";
    openssh.authorizedKeys.keys = [
      ''command="${pkgs.rrsync}/bin/rrsync /var/www/${secrets.hosts.common.b_domain}/html",restrict ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCs2GqjWSQx1CnPj2QOclRD9jBHhc1B/juzdZITF7+EW9+GxV9uV4NZKJVqbbnSNuRIMlaVxuTOEi7ObsIFl7GZEimcenhUnbwlDva4OUtYwwVRpenhjTZTgWaVcU51JFV0rX9Q97pI4KY4Xte4oTIifRvuQp5hroqZKuuhwlnR552iSmKhYADJn0A8ofcsK58ue6SlPE6sEn9xRhtPxtRxMTqtxwqio/yzRDro9V/hxWVjEBCEthA+fVAlktLf+Ly/3+VaXERc9MxzPXhW8l0tEZAi+E75AjQOnz1+Z8CSc/pM5DDex7XUCrbLY1uNCPaoN+7OAh1jjsE67bXQPkzfJQkOBL2eKZQM4IJnmote43Adlzh6QY1okp+1q1a00NrgG0aSJgss4KpiXQelMxN9t+DwqUbGFXuG9IEk/3KREAm2AL2i5XilBwDiiZqX2a4/1rs0GzYIrLuUajnSLnS6eTpVwBHhGPT7LzctlArlVTu1WkoOjC/UQf1uhri0ZPcsoabvPcU6aJEELdJuwjQdpLVgVrB5PImVib83vJfHp0IdMCmbDh2YNrS64Nco5ejDjP3h5aMr3uBwJQsGfWx/ThyxLavBSRysR/SKI1nE/i3GY+GwysXEU85DL4e39l2QnhlexQDy6txFpco9x8kZwh92eaU1TNb14gU+TR5joQ==''
      ''command="${pkgs.rrsync}/bin/rrsync /var/www/${secrets.hosts.common.b_domain}/html",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCkUs+kI8QS71lWZdxSi0Dny+llNM9uGLmWvNlpi7u8''
    ];
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
      #   root = "/var/www/${secrets.hosts.common.b_domain}/html";
      # };

      "${secrets.hosts.common.m_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.m_domain}";
        locations = {
          "/" = {
            return = "302 https://${secrets.hosts.common.b_domain}$request_uri";
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
