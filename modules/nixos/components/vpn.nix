{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.vpn;
in
{
  options.modules.nixos.vpn = {
    enable = lib.mkEnableOption "vpn packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
  };
}