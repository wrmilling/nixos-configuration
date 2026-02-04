{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.ncps;
in
{
  options.modules.nixos.ncps = {
    enable = lib.mkEnableOption "ncps cache proxy";

    enableAnalyticsReporting = lib.mkEnableOption {
      type = lib.types.bool;
      description = "Enable reporting analytics to upstream project";
      default = false;
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      description = "Hostname to serve ncps behind nginx";
      example = "nixcache.example.com";
    };

    cacheDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ncps";
      description = "Base directory for ncps cache data";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8501;
      description = "Local ncps listen port";
    };

    maxSize = lib.mkOption {
      type = lib.types.str;
      default = "50G";
      description = "Maximum ncps cache size";
    };

    secretKeyPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to ncps private key";
      example = "/var/lib/ncps/private-key";
    };

    uploadAuthFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to nginx basic auth file for ncps uploads";
      example = "/var/lib/ncps/upload_auth";
    };

    upstreamCaches = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "https://cache.nixos.org"
      ];
      description = "Upstream cache URLs for ncps";
    };

    upstreamPublicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      description = "Upstream cache public keys for ncps";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.nixos.webhost.enable;
        message = "modules.nixos.ncps requires modules.nixos.webhost.enable = true";
      }
    ];

    services.ncps = {
      enable = true;
      prometheus.enable = false;
      analytics.reporting.enable = cfg.enableAnalyticsReporting;
      cache = {
        hostName = cfg.hostName;
        tempPath = "${cfg.cacheDir}/tmp";
        databaseURL = "sqlite:${cfg.cacheDir}/db/db.sqlite";
        maxSize = cfg.maxSize;
        lru.schedule = "0 5 * * *";
        allowPutVerb = true;
        allowDeleteVerb = true;
        secretKeyPath = cfg.secretKeyPath;
        storage.local = "${cfg.cacheDir}";
        upstream = {
          urls = cfg.upstreamCaches;
          publicKeys = cfg.upstreamPublicKeys;
        };
      };
      server.addr = "127.0.0.1:${toString cfg.port}";
    };

    services.nginx.virtualHosts."${cfg.hostName}" = {
      forceSSL = true;
      enableACME = true;
      extraConfig = ''
        client_max_body_size 512M;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.port}/";
        extraConfig = lib.mkIf (cfg.uploadAuthFile != null) ''
          limit_except GET HEAD {
            auth_basic           "Upload Access Only";
            auth_basic_user_file ${cfg.uploadAuthFile};
          }
        '';
      };
    };
  };
}
