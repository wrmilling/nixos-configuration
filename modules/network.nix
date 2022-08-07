{ config, lib, pkgs, ... }:

{
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  networking.networkmanager.enable = true;
}
