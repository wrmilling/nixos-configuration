{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.filesystem;
in
{
  options.modules.filesystem = {
    enable = lib.mkEnableOption "filesystem packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.exfat
      pkgs.nfs-utils
    ];
  };
}