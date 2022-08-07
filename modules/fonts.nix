{ config, lib, pkgs, ... }:

{
  fonts.fonts = with pkgs; [
    source-code-pro
    font-awesome_4
  ];
}
