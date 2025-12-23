{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.filesystem;
in
{
  options.modules.nixos.filesystem = {
    enable = lib.mkEnableOption "filesystem packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.exfat
      pkgs.nfs-utils
    ];
  };
}