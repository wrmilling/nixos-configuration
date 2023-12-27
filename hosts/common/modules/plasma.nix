{ config, pkgs, lib, callPackage, ... }:

{
  services.xserver = {
    enable = true;
    sddm = {
      enable = true;
    };
    plasma5 = {
      enable = true;
    };
  }
}
