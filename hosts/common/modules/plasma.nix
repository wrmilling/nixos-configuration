{ config, pkgs, lib, callPackage, ... }:

{
  services.xserver = {
    enable = true;
    desktopManager.plasma5 = {
      enable = true;
      runUsingSystemd = true;
    };
    displayManager.sddm = {
     enable = true;
    };
  };
}