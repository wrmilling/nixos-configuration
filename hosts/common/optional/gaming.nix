{ config, lib, pkgs, ... }:

{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    lutris
    heroic
    protonup-qt
  ];
}
