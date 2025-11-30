{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.machineType.desktop;
in
{
  options.modules.machineType.desktop = {
    enable = lib.mkEnableOption "desktop NixOS modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      base.enable = true;
      audio.enable = true;
      filesystem.enable = true;
      fonts.enable = true;
      graphical.enable = true;
      network.enable = true;
      plasma6.enable = true;
    };
  };
}
