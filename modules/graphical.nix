{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mesa
    glxinfo
    alacritty
    firefox
    flameshot
    element-desktop
    gparted
  ];
}
