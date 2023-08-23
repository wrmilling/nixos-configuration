{ pkgs, ... }:

{
  imports = [
    ./alacritty.nix
    ./firefox.nix
    ./i3wm.nix
    ./rofi.nix
    ./xresources.nix
  ];

  home.packages = with pkgs; lib.mkMerge [
    (lib.mkIf stdenv.isx86_64 [
      (vivaldi.override {
        proprietaryCodecs = true;
        enableWidevine = false;
      })
      slack
    ])
    ([
      element-desktop
      cura
      flameshot
      gparted
      volumeicon
    ])  
  ];
}
