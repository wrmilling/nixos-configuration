{ pkgs, lib, config, ... }:

{
  services.keybase.enable = true;
  services.kbfs.enable = true;

  home.packages = with pkgs; lib.mkMerge [
    ( lib.mkIf stdenv.isx86_64 [
      #keybase-gui
    ])
    ([
      keybase
      kbfs
    ])
  ];
}
