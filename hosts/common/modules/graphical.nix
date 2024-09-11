{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.mesa
    pkgs.glxinfo
  ];
}
