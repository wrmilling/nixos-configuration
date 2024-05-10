{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [ box64 ];
}
