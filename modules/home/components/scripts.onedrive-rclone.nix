{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.onedrive-rclone;
  onedrive-rclone = pkgs.writeShellScriptBin "onedrive-rclone" ''
    print_help () {
      ${pkgs.coreutils-full}/bin/cat <<- "EOF"
    usage: onedrive [COMMAND]

    Commands:
      start       Start RClone and mount to ~/OneDrive
      stop        Kill RClone and unmount ~/OneDrive
      help        Print the help documentation

    Examples
      onedrive start
      onedrive stop
      onedrive help
      onedrive
    EOF
    }

    case "$1" in
    stop)
      ${pkgs.procps}/bin/pkill rclone
      ;;
    help)
      print_help
      ;;
    start)
      if ${pkgs.procps}/bin/pgrep -x "rclone" > /dev/null
      then
        echo "RClone is running."
      else
        echo "Launching RClone"
        ${pkgs.coreutils-full}/bin/mkdir -p ~/OneDrive
        ${pkgs.rclone}/bin/rclone --vfs-cache-mode writes mount OneDrive: ~/OneDrive --daemon
      fi
      ;;
    *)
      print_help
      ;;
    esac
  '';
in
{
  options.modules.home.scripts.onedrive-rclone = {
    enable = lib.mkEnableOption "onedrive-rclone packages / settings";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ onedrive-rclone ];
  };
}
