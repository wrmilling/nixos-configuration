{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    bc
    vim
    btop
    tmux
    git
    wget
    chezmoi
    silver-searcher
    viddy
    p7zip
    rsync
    rclone
    exfat
    dnsutils
    gnupg
    pinentry-curses
    minicom
    hut
  ];

}
