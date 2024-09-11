{ lib, pkgs, ... }:
{
  services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
  hardware.graphics.extraPackages = [ pkgs.vaapiVdpau ];
  hardware.nvidia.open = true;
}
