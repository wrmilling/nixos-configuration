{
  config,
  pkgs,
  lib,
  callPackage,
  ...
}:
{
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
    };
  };

  services.xserver = {
    autorun = true;
    xkb.layout = "us";

    desktopManager = {
      xterm.enable = false;
    };

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;

      extraPackages = [
        pkgs.i3status-rust
        pkgs.i3lock
        pkgs.feh
        pkgs.rofi
        pkgs.imagemagick
        pkgs.brightnessctl
        pkgs.playerctl
        pkgs.pavucontrol
      ];
    };
  };

  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
    HandlePowerKey=ignore
  '';

  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.dconf.enable = true;
  services.autorandr.enable = true;
}
