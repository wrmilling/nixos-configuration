{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.bluetooth;
in
{
  options.modules.bluetooth = {
    enable = lib.mkEnableOption "bluetooth packages / settings";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
  };
}