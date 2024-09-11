{
  config,
  lib,
  pkgs,
  ...
}:
{
  fonts.packages = [
    pkgs.source-code-pro
    pkgs.font-awesome_4
    pkgs.corefonts
    pkgs.monaspace
  ];
}
