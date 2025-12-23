{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.visualBoot;
in
{
  options.modules.nixos.visualBoot = {
    enable = lib.mkEnableOption "visual boot packages / settings";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.systemd.enable = true;
    boot.plymouth.enable = true;
    boot.kernelParams = [ "quiet" ];
  };
}