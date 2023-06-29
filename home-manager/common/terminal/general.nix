{ pkgs, lib, config, ... }: 

{
  home.packages = with pkgs; [
    hut
    shellclear
    lynx
    viddy
    silver-searcher
    unstable.git-credential-manager
    magic-wormhole
  ];
}
