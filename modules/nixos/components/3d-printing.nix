{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.threeDPrinting;
in
{
  options.modules.nixos.threeDPrinting = {
    enable = lib.mkEnableOption "3d printing packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.prusa-slicer
    ];
  };
}
