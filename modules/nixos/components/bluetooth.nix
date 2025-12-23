{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.bluetooth;
in
{
  options.modules.nixos.bluetooth = {
    enable = lib.mkEnableOption "bluetooth packages / settings";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
  };
}