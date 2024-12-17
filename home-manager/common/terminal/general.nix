{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = [
    pkgs.hut
    pkgs.shellclear
    pkgs.lynx
    pkgs.viddy
    pkgs.silver-searcher
    pkgs.magic-wormhole-rs
    pkgs.any-nix-shell
  ];
}
