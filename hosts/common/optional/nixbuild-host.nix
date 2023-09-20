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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIrbzUeLjwiQIRcvlojBpdza702AIl1ne5upGVzKBE1n Hermes.BuildHost"
    ];
  };
}
