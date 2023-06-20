{ pkgs, ... }: 

{
  imports = [
    ./atuin.nix
    ./git.nix
    ./gpg.nix
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
