{ pkgs, lib, config, ... }:

{
  services.keybase.enable = true;

  home.packages = with pkgs; [
    keybase
    keybase-gui
    kbfs
  ];
}
