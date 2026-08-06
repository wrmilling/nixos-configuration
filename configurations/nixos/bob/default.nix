{
  config,
  inputs,
  outputs,
  pkgs,
  lib,
  secrets,
  ...
}:
let
  # The custom logo uploaded to the Uptime Kuma status page (/upload/logo1.png), carried over for Gatus's ui.logo/favicon.
  gatusLogo = ./assets/gatus-logo.png;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  sops.secrets."ncps/private_key" = {
    owner = "ncps";
    sopsFile = ../../../secrets/ncps.yaml;
  };

  sops.secrets."ncps/upload_auth" = {
    owner = "nginx";
    sopsFile = ../../../secrets/ncps.yaml;
  };

  sops.secrets."gatus/env" = {
    sopsFile = ../../../secrets/gatus.yaml;
  };

  modules = {
    machineType.server.enable = true;
    nixos.sshd.banner = "${secrets.sshd.banner}";
    nixos.nixbuildHost.enable = true;
    nixos.webhost.enable = true;
    nixos.atuin.enable = true;
    nixos.ncps = {
      enable = true;
      hostName = "nixcache.${secrets.hosts.common.domain}";
      secretKeyPath = config.sops.secrets."ncps/private_key".path;
      uploadAuthFile = config.sops.secrets."ncps/upload_auth".path;
    };
    nixos.forgejoRunner = {
      enable = true;
      domain = secrets.forgejo.domain;
      runnerTokenFile = config.sops.secrets."forgejo/runnerToken".path;
    };
  };

  sops.secrets."forgejo/runnerToken" = {
    sopsFile = ../../../secrets/forgejo.yaml;
  };

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

  services.gatus = {
    enable = true;
    package = pkgs.gatus;
    environmentFile = config.sops.secrets."gatus/env".path;
    settings = {
      ui = {
        title = secrets.gatus.title;
        header = secrets.gatus.title;
        dashboard-heading = "External Service Health";
        dashboard-subheading = "";
        logo = "https://status.${secrets.hosts.common.domain}/logo.png";
        favicon = {
          default = "https://status.${secrets.hosts.common.domain}/logo.png";
          size16x16 = "https://status.${secrets.hosts.common.domain}/logo.png";
          size32x32 = "https://status.${secrets.hosts.common.domain}/logo.png";
        };
        default-sort-by = "name";
      };
      alerting = {
        matrix = {
          server-url = "https://synapse.${secrets.hosts.common.domain}";
          access-token = "\${GATUS_MATRIX_ACCESS_TOKEN}";
          internal-room-id = "\${GATUS_MATRIX_ROOM_ID}";
          default-alert = {
            failure-threshold = 3;
            success-threshold = 2;
            send-on-resolved = true;
          };
        };
      };
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };
      endpoints =
        map
          (
            endpoint:
            endpoint
            // {
              ui.hide-hostname = true;
              ui.hide-port = true;
              ui.hide-url = true;
              alerts = [ { type = "matrix"; } ];
            }
          )
          [
            {
              name = "Homelab Connection";
              group = "Backbone";
              url = "icmp://ipv4.${secrets.hosts.common.domain}";
              conditions = [ "[CONNECTED] == true" ];
            }

            {
              name = "Bart";
              group = "Servers";
              url = "icmp://bart.${secrets.hosts.common.domain}";
              conditions = [ "[CONNECTED] == true" ];
            }
            {
              name = "Bob";
              group = "Servers";
              url = "icmp://bob.${secrets.hosts.common.domain}";
              conditions = [ "[CONNECTED] == true" ];
            }
            {
              name = "Goku";
              group = "Servers";
              url = "icmp://goku.${secrets.hosts.common.domain}";
              conditions = [ "[CONNECTED] == true" ];
            }
            {
              name = "Khan";
              group = "Servers";
              url = "icmp://${secrets.hosts.common.c_domain}";
              conditions = [ "[CONNECTED] == true" ];
            }
            {
              name = "Linus";
              group = "Servers";
              url = "icmp://${secrets.hosts.common.p_domain}";
              conditions = [ "[CONNECTED] == true" ];
            }

            {
              name = "Atuin";
              group = "Services";
              url = "https://atuin.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Authelia";
              group = "Services";
              url = "https://auth.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Calibre";
              group = "Services";
              url = "https://lib.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] == any(200, 302, 401)" ];
            }
            {
              name = "Forgejo";
              group = "Services";
              url = "https://git.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Home Assistant";
              group = "Services";
              url = "https://hass.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Immich";
              group = "Services";
              url = "https://photos.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Mastodon";
              group = "Services";
              url = "https://mastodon.${secrets.hosts.common.domain}/";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              # Bridge only serves its API paths; the root path legitimately 404s.
              name = "Mautrix (Slack)";
              group = "Services";
              url = "https://mbridge-slack.${secrets.hosts.common.domain}/";
              conditions = [ "[STATUS] == any(200, 404)" ];
            }
            {
              name = "Media Requests";
              group = "Services";
              url = "https://requests.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "OpenGist";
              group = "Services";
              url = "https://gist.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Plex";
              group = "Services";
              url = "https://plex.${secrets.hosts.common.domain}/web/index.html#!/";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Synapse (MAS)";
              group = "Services";
              url = "https://mas.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Synapse (Server)";
              group = "Services";
              url = "https://synapse.${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }

            {
              name = "Cowboy";
              group = "Sites";
              url = "https://${secrets.hosts.common.c_domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Homelab";
              group = "Sites";
              url = "https://${secrets.hosts.common.domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Personal";
              group = "Sites";
              url = "https://${secrets.hosts.common.b_domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Personal (Development)";
              group = "Sites";
              url = "https://${secrets.hosts.common.d_domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Personal (Radio)";
              group = "Sites";
              url = "https://${secrets.hosts.common.h_domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Personal (Resume)";
              group = "Sites";
              url = "https://${secrets.hosts.common.w_domain}";
              conditions = [ "[STATUS] < 300" ];
            }
            {
              name = "Small";
              group = "Sites";
              url = "https://${secrets.hosts.common.a_domain}";
              conditions = [ "[STATUS] < 300" ];
            }
          ];
    };
  };

  services.nginx = {
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "${secrets.hosts.common.domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.domain}";
        serverAliases = [
          "www.${secrets.hosts.common.domain}"
        ];
      };

      "${secrets.hosts.common.b_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.b_domain}/html";
        serverAliases = [
          "www.${secrets.hosts.common.b_domain}"
        ];
      };

      "${secrets.hosts.common.d_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.d_domain}";
        serverAliases = [
          "www.${secrets.hosts.common.d_domain}"
        ];
        locations = {
          "/" = {
            return = "301 https://${secrets.hosts.common.b_domain}$request_uri";
          };
        };
      };

      "${secrets.hosts.common.h_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.h_domain}";
        serverAliases = [
          "www.${secrets.hosts.common.h_domain}"
        ];
        locations = {
          "/" = {
            return = "301 https://${secrets.hosts.common.b_domain}/blog$request_uri";
          };
        };
      };

      "${secrets.hosts.common.m_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.m_domain}";
        serverAliases = [
          "www.${secrets.hosts.common.m_domain}"
        ];
        locations = {
          "/" = {
            return = "302 https://${secrets.hosts.common.b_domain}$request_uri";
          };
          "/.well-known/matrix/server" = {
            return = "200 '{\"m.server\": \"synapse.${secrets.hosts.common.domain}:443\"}'";
          };
          "/.well-known/matrix/client" = {
            return = "200 '{\"m.homeserver\": {\"base_url\": \"https://synapse.${secrets.hosts.common.domain}/\"},\"org.matrix.msc2965.authentication\": {\"issuer\": \"https://mas.${secrets.hosts.common.domain}/\",\"account\": \"https://mas.${secrets.hosts.common.domain}/account/\"}}'";
            extraConfig = "add_header Content-Type application/json;\nadd_header \"Access-Control-Allow-Origin\" *;\n";
          };
          "/.well-known/webfinger" = {
            return = "301 https://mastodon.${secrets.hosts.common.domain}$request_uri";
          };
        };
      };

      "${secrets.hosts.common.n_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.domain}";
        # serverAliases = [
        #   "www.${secrets.hosts.common.n_domain}"
        # ];
      };

      "${secrets.hosts.common.r_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.r_domain}";
        serverAliases = [
          "www.${secrets.hosts.common.r_domain}"
        ];
      };

      "${secrets.hosts.common.s_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.s_domain}";
        serverAliases = [
          "www.${secrets.hosts.common.s_domain}"
        ];
      };

      "${secrets.hosts.common.w_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.w_domain}";
        serverAliases = [
          "www.${secrets.hosts.common.w_domain}"
        ];
        locations = {
          "/" = {
            return = "301 https://${secrets.hosts.common.b_domain}/resume$request_uri";
          };
        };
      };

      "${secrets.hosts.common.y_domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/${secrets.hosts.common.domain}";
        serverAliases = [
          "www.${secrets.hosts.common.y_domain}"
        ];
      };

      "status.${secrets.hosts.common.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."= /logo.png".alias = "${gatusLogo}";
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.gatus.settings.web.port}/";
        };
      };

      "atuin.${secrets.hosts.common.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.atuin.port}/";
        };
      };
    };
  };

  system.stateVersion = "24.11";
}
