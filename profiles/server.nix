{ config, lib, pkgs, ... }: 

{
  environment.pathsToLink = [ "/libexec" ];

  imports = [
    ./default.nix
    ../modules/nixbuild-host.nix
  ];
}
