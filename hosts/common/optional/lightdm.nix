{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.xserver.displayManager.lightdm.enable = true;
  services.displayManager.defaultSession = "none+i3";
}
