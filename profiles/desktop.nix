{ config, lib, pkgs, ... }: 

{
  environment.pathsToLink = [ "/libexec" ];

  imports = [
    ./default.nix
    ../modules/development.nix
    ../modules/fonts.nix
    ../modules/graphical.nix
    ../modules/network.nix
    ../modules/xdg-autostart.nix
  ];

  services.xserver.enable = true;

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-curses
    minicom
  ];
}
