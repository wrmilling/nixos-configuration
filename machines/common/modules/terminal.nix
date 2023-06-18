{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    bc
    vim
    btop
    git
    wget
    silver-searcher
    p7zip
    rsync
    rclone
    exfat
    dnsutils
    gnupg
    pass
    pinentry-curses
    minicom
  ];

}
