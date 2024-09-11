{ pkgs, ... }:
{
  imports = [
    ./atuin.nix
    ./fish.nix
    ./general.nix
    ./git.nix
    ./gpg.nix
    ./starship.nix
    ./tmux.nix
    ./vim.nix
  ];
  home.packages = [ pkgs.onedrive ];
}
