{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.pathsToLink = [ "/libexec" ];

  imports = [
    ./default.nix
    ./modules/audio.nix
    ./modules/bluetooth.nix
    ./modules/filesystem.nix
    ./modules/fonts.nix
    ./modules/graphical.nix
    ./modules/network.nix
    ./modules/plasma6.nix
  ];

  services.xserver.enable = true;
  networking.networkmanager.enable = true;
  # programs.nm-applet.enable = true;
}
