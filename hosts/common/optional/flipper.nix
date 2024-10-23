{
  config,
  lib,
  pkgs,
  ...
}:
{
  hardware.flipperzero.enable = true;
  environment.systemPackages = [ pkgs.qflipper ];
}
