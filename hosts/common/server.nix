{ config, lib, pkgs, ... }:

{
  environment.pathsToLink = [ "/libexec" ];

  imports = [
    ./default.nix
    ./modules/sshd.nix
  ];
}
