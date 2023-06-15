{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    bc
    vim
    btop
    tmux
    zellij
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
    pass
    pinentry-curses
    minicom
    hut
    atuin
    shellclear
    lynx
  ];

}
