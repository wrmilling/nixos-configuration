{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    bc
    btop
    vim
    git
    git-crypt
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
