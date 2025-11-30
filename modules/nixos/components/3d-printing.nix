{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.threeDPrinting;
in
{
  options.modules.threeDPrinting = {
    enable = lib.mkEnableOption "3d printing packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.prusa-slicer
    ];
  };
}
