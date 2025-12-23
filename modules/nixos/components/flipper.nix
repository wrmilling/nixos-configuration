{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.flipper;
in
{
  options.modules.nixos.flipper = {
    enable = lib.mkEnableOption "flipper zero packages / settings";
  };

  config = lib.mkIf cfg.enable {
    hardware.flipperzero.enable = true;
    environment.systemPackages = [ pkgs.qFlipper ];
  };
}