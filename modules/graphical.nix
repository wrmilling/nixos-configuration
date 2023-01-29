{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mesa
    glxinfo
    alacritty
    (vivaldi.override {
      proprietaryCodecs = true;
      enaableWidevine = false;
    }) # Won't work on ARM64, but I am ignoring that for now.
    flameshot
    element-desktop
    armcord
    gparted
    gramps
    volumeicon
  ];
}
