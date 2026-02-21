{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.atuin;
in
{
  options.modules.nixos.atuin = {
    enable = lib.mkEnableOption "atuin sync service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.atuin;
      description = "Atuin package to use";
    };

    openRegistration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow new account registration";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Local listen address for the atuin server";
    };

    maxHistoryLength = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Maximum length per history item";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Local listen port for the atuin server";
    };

    path = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "URL path prefix for the atuin server";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the atuin port";
    };

    database = {
      createLocally = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to create a local database for Atuin";
      };

      uri = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "sqlite:///var/lib/atuin/atuin.db";
        description = "Database URI for Atuin";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.atuin = {
      enable = true;
      package = cfg.package;
      openRegistration = cfg.openRegistration;
      host = cfg.host;
      maxHistoryLength = cfg.maxHistoryLength;
      port = cfg.port;
      path = cfg.path;
      openFirewall = cfg.openFirewall;
      database = {
        createLocally = cfg.database.createLocally;
        uri = cfg.database.uri;
      };
    };

    systemd.services.atuin.serviceConfig = {
      StateDirectory = "atuin";
      StateDirectoryMode = "0700";
    };
  };
}
