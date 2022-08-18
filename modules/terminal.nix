{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    bc
    vim
    htop
    tmux
    git
    zsh
    wget
    chezmoi
    silver-searcher
    viddy
    p7zip
    rsync
    rclone
  ];
}
