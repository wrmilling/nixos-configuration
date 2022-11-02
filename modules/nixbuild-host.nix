{ config, lib, pkgs, ... }:

{
  users.users.nixbuild = {
    uid = 2000;
    shell = pkgs.zsh;
    isNormalUser = true;
    home = "/home/nixbuild";
    description = "NixOS Builder";
    extraGroups = [];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFb0IqUwwgNsdGWglqvva2//ch40WRhE5FmbGMqo5FzA Hermes.Nixbuild"
    ];
  };
}
