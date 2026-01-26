{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.graphical.keybase;
in
{
  options.modules.home.graphical.keybase = {
    enable = lib.mkEnableOption "keybase packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.keybase.enable = true;
    services.kbfs.enable = true;

    home.packages = lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isx86_64 [
        #pkgs.keybase-gui
      ])
      [
        pkgs.keybase
        pkgs.kbfs
      ]
    ];
  };
}
