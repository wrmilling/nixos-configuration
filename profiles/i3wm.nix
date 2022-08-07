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
        i3status-rust
        feh
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
    inactiveOpacity = 0.8;
  };
}
