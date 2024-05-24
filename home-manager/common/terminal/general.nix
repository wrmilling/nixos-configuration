{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    hut
    shellclear
    lynx
    viddy
    silver-searcher
    magic-wormhole-rs
    hugo
    any-nix-shell
  ];
}
