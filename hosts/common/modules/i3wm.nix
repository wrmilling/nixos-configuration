{ config, pkgs, lib, callPackage, ... }: 

{
  services.xserver = {
    autorun = true; 
    layout = "us";
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
        dmenu
        rofi
        lightlocker
        imagemagick
        i3status-rust
        i3lock
        feh
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
 
  services.picom = {
    enable = true;
    backend = "glx";
    inactiveOpacity = 0.95;
    opacityRules = [
      "100:name *= 'i3lock'"
    ];
  };

  services.autorandr.enable = true;
}
