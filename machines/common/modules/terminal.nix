{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    bc
    vim
    btop
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
    shellclear
    lynx
  ];

}
