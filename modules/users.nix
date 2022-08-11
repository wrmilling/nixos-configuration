{ config, lib, pkgs, ... }:

{
  users.users.w4cbe = {
    uid = 1000;
    shell = pkgs.zsh;
    isNormalUser = true;
    home = "/home/w4cbe";
    description = "Winston R. Milling";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "uucp"
      "dialout"
    ];
  };
}
