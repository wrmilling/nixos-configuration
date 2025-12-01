{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.keybase.enable = true;
  services.kbfs.enable = true;

  home.packages = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isx86_64 [
      #pkgs.keybase-gui
    ])
    [
      pkgs.keybase
      pkgs.kbfs
    ]
  ];
}
