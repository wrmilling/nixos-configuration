{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    htop
    tmux
    git
    zsh
    wget
    chezmoi
  ];
}
