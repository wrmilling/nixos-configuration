{ lib, pkgs, ... }:
{
  services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
  hardware.graphics.extraPackages = with pkgs; [ vaapiVdpau ];
  hardware.nvidia.open = true;
}
