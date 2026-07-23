{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.cv;
  cv = pkgs.writeScriptBin "cv" ''
    #!${pkgs.fish}/bin/fish
    function print_help
      echo "usage: cv [file]"
      echo ""
      echo "Push a file to an attached Android device via adb."
      echo "If no file is given, the latest screenshot on the Desktop is used"
      echo "(matching: Screenshot YYYY-MM-DD at HH.MM.SS AM/PM.png)."
    end

    if set -q argv[1]; and contains -- $argv[1] -h --help
      print_help
      exit 0
    end

    if set -q argv[1]
      set target $argv[1]
    else
      set target (${pkgs.coreutils-full}/bin/ls -t ~/Desktop/Screenshot\ *.png 2>/dev/null | head -1)
      if test -z "$target"
        echo "cv: no screenshot found on Desktop" >&2
        exit 1
      end
    end

    if not test -f "$target"
      echo "cv: file not found: $target" >&2
      exit 1
    end

    echo "cv: pushing '$target' to /sdcard/Copied/ ..."
    ${pkgs.android-tools}/bin/adb push "$target" /sdcard/Copied/
  '';
in
{
  options.modules.home.scripts.cv = {
    enable = lib.mkEnableOption "cv - push screenshots to Android via adb";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cv ];
  };
}
