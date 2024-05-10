{
  config,
  lib,
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    source-code-pro
    font-awesome_4
    corefonts
    monaspace
  ];
}
