{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nvidia;
in
{
  options.modules.nvidia = {
    enable = lib.mkEnableOption "nvidia packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
    hardware.graphics.extraPackages = [ pkgs.libva-vdpau-driver ];
    hardware.nvidia.open = true;
  };
}