{ config, lib, pkgs, ... }:

{
  environment.pathsToLink = [ "/libexec" ];

  imports = [
    ./default.nix
    ./modules/filesystems.nix
    ./modules/sshd.nix
  ];
}
