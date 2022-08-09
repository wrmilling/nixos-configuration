{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    vim
    htop
    tmux
    git
    zsh
    wget
    chezmoi
    silver-searcher
  ];
}
