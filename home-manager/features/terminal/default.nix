{ pkgs, ... }: 

{
  imports = [
    ./atuin.nix
    ./git.nix
    ./gpg.nix
    ./tmux.nix
  ];
  home.packages = with pkgs; [
    hut
    shellclear
    lynx
    viddy
    silver-searcher
  ];
}