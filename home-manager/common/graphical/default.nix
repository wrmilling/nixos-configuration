{ pkgs, ... }:

{
  imports = [
    ./alacritty.nix
    ./firefox.nix
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
    (lib.mkIf stdenv.isAarch64 [
      vivaldi
    ])
    ([
      element-desktop
      cura
      flameshot
      gparted
      volumeicon
      brave-multiarch
    ])
  ];
}
