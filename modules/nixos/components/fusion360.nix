{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.fusion360;
in
{
  options.modules.nixos.fusion360 = {
    enable = lib.mkEnableOption "Autodesk Fusion 360 (Windows CAD/CAM, run via Wine)";
  };

  config = lib.mkIf cfg.enable {
    # Wine's WoW64 prefix needs 32-bit graphics drivers alongside the 64-bit ones.
    hardware.graphics.enable32Bit = true;

    environment.systemPackages = [ pkgs.fusion360 ];
  };
}
