{ pkgs, lib, ... }:
{
  imports = [
    ./alacritty.nix
    ./firefox.nix
    ./xresources.nix
  ];

  home.packages = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isx86_64 [ pkgs.slack ])
    (lib.mkIf pkgs.stdenv.isAarch64 [ ])
    [
      pkgs.element-desktop
      # cura
      pkgs.flameshot
      pkgs.gparted
      # volumeicon
      pkgs.keepassxc
      pkgs.vlc
    ]
  ];
}
