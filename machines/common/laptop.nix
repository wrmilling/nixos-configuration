{ config, lib, pkgs, ... }: 

{
  environment.pathsToLink = [ "/libexec" ];

  imports = [
    ./default.nix
    ./modules/audio.nix
    ./modules/bluetooth.nix
    ./modules/fonts.nix
    ./modules/graphical.nix
    ./modules/i3wm.nix
    ./modules/network.nix
  ];

  services.xserver.enable = true;
}