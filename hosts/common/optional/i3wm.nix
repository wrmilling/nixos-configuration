{
  config,
  pkgs,
  lib,
  callPackage,
  ...
}: {
  services.xserver = {
    autorun = true;
    xkb.layout = "us";
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
      };
    };

    desktopManager = {
      xterm.enable = false;
    };

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;

      extraPackages = with pkgs; [
        i3status-rust
        i3lock
        feh
        rofi
        imagemagick
        brightnessctl
        playerctl
        pavucontrol
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
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  programs.dconf.enable = true;
  services.autorandr.enable = true;
}
