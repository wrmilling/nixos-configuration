{ pkgs, ... }: 

{
  imports = [
    ./atuin.nix
    ./fish.nix
    ./git.nix
    ./gpg.nix
    ./starship.nix
    ./tmux.nix
    ./vim.nix
  ];
  home.packages = with pkgs; [
    hut
    shellclear
    lynx
    viddy
    silver-searcher
  ];
}
