{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = [ pkgs.box64 ];
}
