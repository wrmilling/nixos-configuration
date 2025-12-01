{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = [ pkgs.prismlauncher ];
}
