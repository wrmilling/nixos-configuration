{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.flipper;
in
{
  options.modules.flipper = {
    enable = lib.mkEnableOption "flipper zero packages / settings";
  };

  config = lib.mkIf cfg.enable {
    hardware.flipperzero.enable = true;
    environment.systemPackages = [ pkgs.qFlipper ];
  };
}