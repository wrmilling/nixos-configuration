{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vscode
    dtc
    inkscape
    nixpkgs-review
  ];
}
