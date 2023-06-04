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

    displayManager = {
      lightdm.enable = true;
      defaultSession = "none+i3";  
    };

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;

      extraPackages = with pkgs; [
        dmenu
        i3lock
        imagemagick
        xautolock
        i3status-rust
        feh
        brightnessctl
        playerctl
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
}
