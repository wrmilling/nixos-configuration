{ config, lib, pkgs, ... }:

{
  imports = [
    ./wireless.nix
  ];

  environment.etc."machine-info".text = lib.mkDefault ''
    CHASSIS="laptop"
  '';

  programs.light.enable = true;

  # Supposedly better for the SSD.
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];
}
