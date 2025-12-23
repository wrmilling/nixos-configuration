{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.smartcard;
in
{
  options.modules.nixos.smartcard = {
    enable = lib.mkEnableOption "smartcard packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.pcscd = {
      enable = true;
      plugins = [ pkgs.ccid ];
    };
  };
}