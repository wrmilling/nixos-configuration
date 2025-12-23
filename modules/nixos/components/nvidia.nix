{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.nvidia;
in
{
  options.modules.nixos.nvidia = {
    enable = lib.mkEnableOption "nvidia packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
    hardware.graphics.extraPackages = [ pkgs.libva-vdpau-driver ];
    hardware.nvidia.open = true;
  };
}