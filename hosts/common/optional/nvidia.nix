{ lib, pkgs, ... }:
{
  services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
  hardware.graphics.extraPackages = [ pkgs.libva-vdpau-driver ];
  hardware.nvidia.open = true;
}
