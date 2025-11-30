{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.smartcard;
in
{
  options.modules.smartcard = {
    enable = lib.mkEnableOption "smartcard packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.pcscd = {
      enable = true;
      plugins = [ pkgs.ccid ];
    };
  };
}