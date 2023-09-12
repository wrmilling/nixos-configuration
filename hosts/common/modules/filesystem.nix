{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    exfat
    nfs-utils
  ];
}
