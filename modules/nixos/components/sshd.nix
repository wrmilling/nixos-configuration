{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.sshd;
in
{
  options.modules.nixos.sshd = {
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
      banner = config.modules.nixos.sshd.banner;
      settings = {
        PermitRootLogin = lib.mkDefault "no";
        PasswordAuthentication = lib.mkDefault false;
      };
    };

    # Enable Fail2Ban
    services.fail2ban.enable = lib.mkDefault true;
  };
}