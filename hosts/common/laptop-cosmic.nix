{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.pathsToLink = ["/libexec"];

  imports = [
    ./default.nix
    ./modules/audio.nix
    ./modules/bluetooth.nix
    ./optional/cosmic.nix
    ./modules/filesystem.nix
    ./modules/fonts.nix
    ./modules/graphical.nix
    # ./modules/i3wm.nix
    # ./modules/lightdm.nix
    ./modules/network.nix
  ];

  services.xserver.enable = true;
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;
}
