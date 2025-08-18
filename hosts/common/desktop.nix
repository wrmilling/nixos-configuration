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
    ./modules/filesystem.nix
    ./modules/fonts.nix
    ./modules/graphical.nix
    ./modules/network.nix
    ./modules/plasma6.nix
  ];

  services.xserver.enable = true;
}
