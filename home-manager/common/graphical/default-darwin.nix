{ pkgs, ... }:
{
  imports = [
    ./alacritty.nix
    ./xresources.nix
  ];
  home.packages = [ ];
}
