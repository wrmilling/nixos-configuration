{ config, lib, pkgs, ... }: 

{
  environment.pathsToLink = [ "/libexec" ];

  imports = [
    ./desktop.nix
    ../modules/bluetooth.nix
  ];
}
