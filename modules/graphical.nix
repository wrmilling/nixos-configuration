{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mesa
    glxinfo
    alacritty
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = false;
    }) # Won't work on ARM64, but I am ignoring that for now.
    flameshot
    element-desktop
    discord
    slack
    gparted
    gramps
    volumeicon
  ];
}
