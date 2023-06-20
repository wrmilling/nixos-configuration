{ config, pkgs, ... }:

let
  bsodlock = pkgs.writeShellScriptBin "bsodlock" ''
    #!${pkgs.bashInteractive}/bin/sh
    set -eu

    # lock the screen
    ${pkgs.i3lock}/bin/i3lock -i $HOME/.local/share/wallpapers/bsod.png -e $@

    # sleep 1 adds a small delay to prevent possible race conditions with suspend
    #sleep 1

    exit 0
  '';
in
{
  home.packages = [ bsodlock ];
}