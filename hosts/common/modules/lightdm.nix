{ config, lib, pkgs, ... }:

{
    services.xserver.displayManager = {
      lightdm.enable = true;
      defaultSession = "xfce+i3";  
    };
}
