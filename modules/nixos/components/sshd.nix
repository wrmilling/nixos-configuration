{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.sshd;
in
{
  options.modules.sshd = {
    enable = lib.mkEnableOption "sshd packages / settings";
    banner = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "text of the sshd banner";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = lib.mkDefault true;
      banner = config.modules.sshd.banner;
      settings = {
        PermitRootLogin = lib.mkDefault "no";
        PasswordAuthentication = lib.mkDefault false;
      };
    };

    # Enable Fail2Ban
    services.fail2ban.enable = lib.mkDefault true;
  };
}