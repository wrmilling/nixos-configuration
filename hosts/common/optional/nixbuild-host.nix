{ config, lib, pkgs, ... }:

{
  users.users.nixbuild = {
    uid = 2000;
    shell = pkgs.fish;
    isNormalUser = true;
    home = "/home/nixbuild";
    description = "NixOS Builder";
    extraGroups = [];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/hRd7PJ/Qby/nB34LNkOPkwyTsc2eJAyaL0ANH1V+h Hermes.BuildHost"
    ];
  };
}
