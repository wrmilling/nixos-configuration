{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.graphical;
in
{
  options.modules.nixos.graphical = {
    enable = lib.mkEnableOption "graphical packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.mesa
      pkgs.mesa-demos
    ];
  };
}