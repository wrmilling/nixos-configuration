{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    bc
    vim
    btop
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
    exfat
    dnsutils
  ];
}
