{ config, pkgs, ... }:
let
  i3exit = pkgs.writeShellScriptBin "i3exit" ''
    set -eu

    lock() {
        bsodlock
    }

    case "$1" in
        lock)
            lock
            ;;
        logout)
            i3-msg exit
            ;;
        suspend)
            lock && systemctl suspend
            ;;
        hibernate)
            lock && systemctl hibernate
            ;;
        reboot)
            systemctl reboot
            ;;
        shutdown)
            systemctl poweroff
            ;;
        *)
            echo "Usage: $0 {lock|logout|suspend|hibernate|reboot|shutdown}"
            exit 2
    esac

    exit 0
  '';
in
{
  home.packages = [ i3exit ];
}
