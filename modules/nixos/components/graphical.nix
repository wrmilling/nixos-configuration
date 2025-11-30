{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.graphical;
in
{
  options.modules.graphical = {
    enable = lib.mkEnableOption "graphical packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.mesa
      pkgs.mesa-demos
    ];
  };
}