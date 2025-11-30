{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.vpn;
in
{
  options.modules.vpn = {
    enable = lib.mkEnableOption "vpn packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
  };
}