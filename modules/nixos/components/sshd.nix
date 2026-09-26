{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.sshd;
  bannerFile = pkgs.writeText "sshd-banner" cfg.banner;
  userBannerFiles = lib.mapAttrs (
    user: text: pkgs.writeText "sshd-banner-${user}" text
  ) cfg.userBanners;
in
{
  options.modules.nixos.sshd = {
    enable = lib.mkEnableOption "sshd packages / settings";
    banner = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "text of the sshd banner shown to most users";
    };
    userBanners = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        {
          "username" = "banner text shown before authentication for this user";
        }
      '';
      description = "Per-user sshd banner text keyed by SSH user name. Each entry emits a Match User block overriding the default banner for that user.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        Banner = lib.mkIf (cfg.banner != "") (toString bannerFile);
        PermitRootLogin = lib.mkDefault "no";
        PasswordAuthentication = lib.mkDefault false;
      };
      matchBlocks = lib.mapAttrs' (
        user: text:
        lib.nameValuePair "user-${user}" {
          match = "User ${user}";
          banner = toString userBannerFiles.${user};
        }
      ) cfg.userBanners;
    };

    services.fail2ban.enable = lib.mkDefault true;
  };
}
